classdef AsyncTaskBuilder < handle

    properties (SetAccess = private)
        onStartFunction;
        onCancelFunction;
        onErrorFunction;
        eachDataCallback;
        taskDoneCallback;
        taskFailedCallback;
    end

    methods

        function obj = onStart(obj, onStartFunction)
            obj.onStartFunction = onStartFunction;
        end

        function obj = onCancel(obj, onCancelFunction)
            obj.onCancelFunction = onCancelFunction;
        end

        function obj = onError(obj, onErrorFunction)
            obj.onErrorFunction = onErrorFunction;
        end

        function obj = onEachData(obj, eachDataCallback)
            obj.eachDataCallback = eachDataCallback;
        end

        function obj = onTaskDone(obj, taskDoneCallback)
            obj.taskDoneCallback = taskDoneCallback;
        end

        function obj = onTaskFailed(obj, taskFailedCallback)
            obj.taskFailedCallback = taskFailedCallback;
        end

        function asyncTask = build(obj)
            worker = AsyncFunctionWorker(obj.onStartFunction, ...
                obj.onCancelFunction, obj.onErrorFunction);
            asyncTask = AsyncTask.forWorker(worker);
            asyncTask.eachDataCallback = obj.eachDataCallback;
            asyncTask.taskDoneCallback = obj.taskDoneCallback;
            asyncTask.taskFailedCallback = obj.taskFailedCallback;
        end
    end
end