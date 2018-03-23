classdef AsyncSignal < handle

    properties (Constant)
        TASK_DONE = 0;
        TASK_FAILED = 1;
        CANCEL_TASK = 2;
    end

    properties (SetAccess = private)
        value;
    end

    methods
        function obj = AsyncSignal(value)
            obj.value = value;
        end
    end
end