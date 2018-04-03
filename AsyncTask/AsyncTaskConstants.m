classdef AsyncTaskConstants
    
    properties (Constant)
        MESSAGE_CALLBACK_SET_AFTER_START = 'Cannot set callbacks after task has started';
        MESSAGE_TASK_ALREADY_STARTED = 'Task already started';
        MESSAGE_TASK_NOT_STARTED = 'Task not yet started';
        MESSAGE_TASK_NOT_RUNNING = 'Task not currently running';
        MESSAGE_POLL_ATTEMPT_ON_DATA_QUEUE = 'Cannot poll from queue if eachDataCallback is set';
        MESSAGE_SET_OUT_ARGS_COUNT_AFTER_START = 'Cannot set out args count after task has started';
        MESSAGE_AMBIGUOUS_OUT_ARGS_COUNT = ['Could not determine exact number of output arguments - ' ...
            'specify it explicitly by calling setOutArgsCount(count)'];
        EXCEPTION_OUT_ARGS_COUNT_NOT_SET_ID = 'AsyncTask:startTask';
        EXCEPTION_OUT_ARGS_COUNT_NOT_SET_MSG = AsyncTaskConstants.MESSAGE_AMBIGUOUS_OUT_ARGS_COUNT;
        EXCEPTION_INVALID_OUT_ARGS_COUNT_ID = 'AsyncTask:setOutArgsCount';
        EXCEPTION_INVALID_OUT_ARGS_COUNT_MSG = 'Invalid out args count value - should be positive integer';
        EXCEPTION_OUT_ARGS_COUNT_NON_NOEGATIVE_ID = 'AsyncTask:setOutArgsCount';
        EXCEPTION_OUT_ARGS_COUNT_NON_NOEGATIVE_MSG = 'Cannot change out args count if it''s unambiguous';
        EXCEPTION_INVALID_WORKER_PASSED_ID = 'AsyncTask:forWorker';
        EXCEPTION_INVALID_WORKER_PASSED_MSG = 'Passed object is not an instance of AsyncWorker class';
    end

    methods (Static)

        function exception = notAsyncWorkerInstanceException()
            exception = MException(...
                AsyncTaskConstants.EXCEPTION_INVALID_WORKER_PASSED_ID, ...
                AsyncTaskConstants.EXCEPTION_INVALID_WORKER_PASSED_MSG);
        end

        function exception = outArgsCountNotSetException()
            exception = MException(...
                AsyncTaskConstants.EXCEPTION_OUT_ARGS_COUNT_NOT_SET_ID, ...
                AsyncTaskConstants.EXCEPTION_OUT_ARGS_COUNT_NOT_SET_MSG);
        end

        function exception = invalidOutArgsCountException()
            exception = MException(...
                AsyncTaskConstants.EXCEPTION_INVALID_OUT_ARGS_COUNT_ID, ...
                AsyncTaskConstants.EXCEPTION_INVALID_OUT_ARGS_COUNT_MSG);
        end

        function exception = nonNegativeOutArgsCountException()
            exception = MException(...
                AsyncTaskConstants.EXCEPTION_OUT_ARGS_COUNT_NON_NOEGATIVE_ID, ...
                AsyncTaskConstants.EXCEPTION_OUT_ARGS_COUNT_NON_NOEGATIVE_MSG);
        end
    end
end