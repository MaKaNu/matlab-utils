classdef AsyncTask < handle

    properties (Constant, Access = private)
        AWAIT_WORKER_QUEUE_RETRY_SECONDS = 0.5;
    end
    
    properties (SetAccess = private)
        started;
        cancelled;
        done;
        failed;
        result;
        exception;
    end

    properties
        eachDataCallback;
        taskDoneCallback;
        taskFailedCallback;
    end

    properties (Access = private)
        asyncWorker;
        signalCatchQueue;
        fromWorkerQueue;
        toWorkerQueue;
        toWorkerQueueListener;
        outArgsCount;
        workerJob;
    end

    methods (Static)

        function task = forWorker(asyncWorker)
            if isa(asyncWorker, 'AsyncWorker')
                task = AsyncTask(asyncWorker);
            else
                throw(AsyncTaskConstants.notAsyncWorkerInstanceException());
            end
        end

        function builder = builder()
            builder = AsyncTaskBuilder();
        end
    end

    methods

        function start(obj, varargin)
            if ~obj.started
                obj.startTask(varargin{:});
                obj.started = true;
            else
                disp(AsyncTaskConstants.MESSAGE_TASK_ALREADY_STARTED);
            end
        end

        function cancel(obj)
            if obj.started && ~obj.cancelled && ~obj.done
                obj.cancelTask();
                obj.cancelled = true;
            else
                disp(AsyncTaskConstants.MESSAGE_TASK_NOT_RUNNING);
            end
        end

        function data = pollData(obj)
            if obj.started
                data = obj.tryPollData();
            else
                disp(AsyncTaskConstants.MESSAGE_TASK_NOT_STARTED);
            end
        end

        function available = isDataAvailable(obj)
            if obj.isFromWorkerQueuePollable()
                available = obj.fromWorkerQueue.QueueLength > 0;
            else
                disp(AsyncTaskConstants.MESSAGE_POLL_ATTEMPT_ON_DATA_QUEUE);
                available = false;
            end
        end

        function sendData(obj, data)
            if obj.started && ~obj.cancelled && ~obj.done
                obj.toWorkerQueue.send(data);
            else
                disp(AsyncTaskConstants.MESSAGE_TASK_NOT_RUNNING);
            end
        end

        function setOutArgsCount(obj, outArgsCount)
            if ~obj.started
                obj.assertDefaultOutArgsCountNegative();
                obj.validateOutArgsCount(outArgsCount)
                obj.outArgsCount = outArgsCount;
            else
                disp(AsyncTaskConstants.MESSAGE_SET_OUT_ARGS_COUNT_AFTER_START);
            end
        end
    end

    methods (Access = private)

        function obj = AsyncTask(asyncWorker)
            obj.started = false;
            obj.cancelled = false;
            obj.done = false;
            obj.failed = false;
            obj.asyncWorker = asyncWorker;
            obj.initOutArgsCount(asyncWorker);
        end

        function initOutArgsCount(obj, asyncWorker)
            obj.outArgsCount = asyncWorker.getDefaultOutArgsCount();
            if obj.outArgsCount < 0
                obj.outArgsCount = [];
                disp(AsyncTaskConstants.MESSAGE_AMBIGUOUS_OUT_ARGS_COUNT);
            end
        end

        function startTask(obj, varargin)
            obj.assertOutArgsCountSet();
            obj.initClientQueues();
            obj.workerJob = obj.startWorkerJob(varargin{:});
            obj.awaitToWorkerQueue();
        end

        function assertOutArgsCountSet(obj)
            if isempty(obj.outArgsCount)
                throw(AsyncTaskConstants.outArgsCountNotSetException());
            end
        end

        function initClientQueues(obj)
            obj.fromWorkerQueue = obj.createFromWorkerQueue();
            obj.signalCatchQueue = obj.createSignalCatchQueue();
        end

        function queue = createFromWorkerQueue(obj)
            if obj.isToWorkerQueuePollable()
                queue = parallel.pool.PollableDataQueue;
            else
                queue = parallel.pool.DataQueue;
                listener = queue.afterEach(@obj.handleIncomingToWorkerQueue);
                obj.toWorkerQueueListener = listener;
            end
        end

        function handleIncomingToWorkerQueue(obj, queue)
            obj.toWorkerQueue = queue;
            delete(obj.toWorkerQueueListener);
            obj.fromWorkerQueue.afterEach(@obj.eachDataCallback);
        end

        function queue = createSignalCatchQueue(obj)
            queue = parallel.pool.DataQueue;
            queue.afterEach(@obj.onQueueDataReceived);
        end

        function onQueueDataReceived(obj, data)
            if isa(data, 'AsyncSignal')
                obj.handleSignal(data);
            else
                obj.fromWorkerQueue.send(data);
            end
        end

        function handleSignal(obj, signal)
            switch signal.value
                case AsyncSignal.TASK_DONE
                    obj.handleTaskDone();
                case AsyncSignal.TASK_FAILED
                    obj.handleTaskFailed();
            end
        end

        function handleTaskDone(obj)
            obj.done = true;
            obj.workerJob.wait();
            obj.fetchWorkerOutput();
            if ~isempty(obj.taskDoneCallback)
                obj.taskDoneCallback(obj.result);
            end
        end

        function fetchWorkerOutput(obj)
            result = cell(1, obj.outArgsCount);
            [result{:}] = obj.workerJob.fetchOutputs();
            switch length(result)
                case 0
                    obj.result = [];
                case 1
                    obj.result = result{1};
                otherwise
                    obj.result = result;
            end
        end

        function handleTaskFailed(obj)
            obj.failed = true;
            obj.workerJob.wait();
            obj.exception = obj.workerJob.Error;
            if ~isempty(obj.taskFailedCallback)
                obj.taskFailedCallback(obj.exception);
            end
        end

        function workerJob = startWorkerJob(obj, varargin)
            obj.asyncWorker.setExpectedOutArgsCount(obj.outArgsCount);
            worker = obj.asyncWorker;
            workerJob = parfeval(@worker.startWorker, ...
                obj.outArgsCount, obj.signalCatchQueue, varargin{:});
        end

        function awaitToWorkerQueue(obj)
            if obj.isToWorkerQueuePollable()
                while obj.fromWorkerQueue.QueueLength == 0
                    pause(obj.AWAIT_WORKER_QUEUE_RETRY_SECONDS);
                end
                obj.toWorkerQueue = obj.fromWorkerQueue.poll();
            else
                while isempty(obj.toWorkerQueue)
                    pause(obj.AWAIT_WORKER_QUEUE_RETRY_SECONDS);
                end
            end
        end

        function pollable = isToWorkerQueuePollable(obj)
            pollable = isempty(obj.eachDataCallback);
        end

        function cancelTask(obj)
            if ~isempty(obj.workerJob)
                cancel(obj.workerJob);
                obj.sendCancelSignal();
                obj.workerJob = [];
            end
        end

        function sendCancelSignal(obj)
            signal = AsyncSignal(AsyncSignal.CANCEL_TASK);
            obj.sendData(signal);
        end

        function data = tryPollData(obj)
            if obj.isFromWorkerQueuePollable()
                data = obj.fromWorkerQueue.poll();
            else
                data = [];
                disp(AsyncTaskConstants.MESSAGE_POLL_ATTEMPT_ON_DATA_QUEUE);
            end
        end

        function pollable = isFromWorkerQueuePollable(obj)
            pollable = isa(obj.fromWorkerQueue, 'parallel.pool.PollableDataQueue');
        end

        function assertDefaultOutArgsCountNegative(obj)
            if ~(obj.asyncWorker.getDefaultOutArgsCount() < 0)
                throw(AsyncTaskConstants.nonNegativeOutArgsCountException());
            end
        end

        function validateOutArgsCount(obj, outArgsCount)
            if ~obj.isOutArgsCountValid(outArgsCount);
                throw(AsyncTaskConstants.invalidOutArgsCountException());
            end
        end

        function valid = isOutArgsCountValid(obj, outArgsCount)
            valid = isa(outArgsCount, 'double') ...
                && mod(outArgsCount, 1) == 0 ...
                && outArgsCount >= 0;
        end
    end
end