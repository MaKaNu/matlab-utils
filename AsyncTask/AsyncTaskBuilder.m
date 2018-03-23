classdef AsyncTaskBuilder < handle

    properties (SetAccess = private)
        onStartFunction;
        onCancelFunction;
        onErrorFunction;
        taskEachDataCallback;
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

        function obj = onTaskEachData(obj, taskEachDataCallback)
            obj.taskEachDataCallback = taskEachDataCallback;
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
            asyncTask.taskEachDataCallback = obj.taskEachDataCallback;
            asyncTask.taskDoneCallback = obj.taskDoneCallback;
            asyncTask.taskFailedCallback = obj.taskFailedCallback;
        end
    end
end