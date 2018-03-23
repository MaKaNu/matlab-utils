classdef (Abstract) AsyncWorker < handle

    properties (Access = private)
        toClientQueue;
        fromClientQueue;
        signalCatchQueue;
    end

    properties (Access = protected)
        expectedOutArgsCount;
    end

    methods

        function onStart(obj);
            ;
        end

        function onCancel(obj);
            ;
        end

        function onError(obj, exception);
            ;
        end
    end

    methods

        function varargout = startWorker(obj, toClientQueue, varargin)
            try
                obj.initWorker(toClientQueue);
                varargout = cell(1, obj.expectedOutArgsCount);
                [varargout{:}] = obj.onStart(varargin{:});
                obj.sendDoneSignal();
            catch ME
                obj.sendFailedSignal();
                obj.onError(ME);
                rethrow(ME);
            end
        end
        
        function data = pollData(obj)
            data = obj.fromClientQueue.poll();
        end

        function sendData(obj, data)
            obj.toClientQueue.send(data);
        end

        function available = isDataAvailable(obj)
            available = obj.fromClientQueue.QueueLength > 0;
        end

        function count = getDefaultOutArgsCount(obj)
            count = nargout([class(obj) '>' class(obj) '.onStart']);
        end

        function setExpectedOutArgsCount(obj, count)
            obj.expectedOutArgsCount = count;
        end
    end

    methods (Access = private)

        function initWorker(obj, toClientQueue)
            obj.initWorkerQueues(toClientQueue);
            obj.sendData(obj.signalCatchQueue);
        end

        function initWorkerQueues(obj, toClientQueue)
            obj.toClientQueue = toClientQueue;
            obj.fromClientQueue = parallel.pool.PollableDataQueue;
            obj.signalCatchQueue = parallel.pool.DataQueue;
            obj.signalCatchQueue.afterEach(@obj.onQueueDataReceived);
        end

        function onQueueDataReceived(obj, data)
            if isa(data, 'AsyncSignal')
                obj.handleSignal(data);
            else
                obj.fromClientQueue.send(data);
            end
        end

        function handleSignal(obj, signal)
            switch signal.value
                case AsyncSignal.CANCEL_TASK
                    obj.onCancel();
            end
        end

        function sendDoneSignal(obj)
            signal = AsyncSignal(AsyncSignal.TASK_DONE);
            obj.sendData(signal);
        end

        function sendFailedSignal(obj)
            signal = AsyncSignal(AsyncSignal.TASK_FAILED);
            obj.sendData(signal);
        end
    end
end