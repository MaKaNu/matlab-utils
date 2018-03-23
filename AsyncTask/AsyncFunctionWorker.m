classdef AsyncFunctionWorker < AsyncWorker

    properties (Access = private)
        doOnStart;
        doOnCancel;
        doOnError;
    end

    methods
        function obj = AsyncFunctionWorker(doOnStart, doOnCancel, doOnError)
            obj.doOnStart = doOnStart;
            obj.doOnCancel = doOnCancel;
            obj.doOnError = doOnError;
        end

        function varargout = onStart(obj, varargin)
            if ~isempty(obj.doOnStart)
                varargout = cell(1, obj.expectedOutArgsCount);
                [varargout{:}] = obj.doOnStart(obj, varargin{:});
            else
                varargout = {};
            end
        end

        function onCancel(obj)
            if ~isempty(obj.doOnCancel)
                obj.doOnCancel(obj);
            end
        end

        function onError(obj, exception)
            if ~isempty(obj.doOnError)
                obj.doOnError(obj, exception);
            end
        end

        function count = getDefaultOutArgsCount(obj)
            count = nargout(obj.doOnStart);
        end
    end
end