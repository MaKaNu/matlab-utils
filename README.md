# matlab-utils

## AsyncTask
Matlab parallel code execution wrapped in easy-to-use set of classes.
Larger explanation in [this](https://medium.com/@tomwyr/asynctask-matlab-parallel-code-execution-made-easier-70cd14101073) Medium article.
### Example
1. Extend AsyncWorker class:
```matlab
classdef MessageWorker < AsyncWorker
    ...
end
```
2. Specify code you want to run in background by overriding its `onStart`, `onCancel` and `onError` methods (each of these is optional):
```matlab
classdef MessageWorker < AsyncWorker

    methods
        function result = onStart(obj, greeting)
            message = ['Worker started with message: ' greeting];
            result = message;
        end

        function onCancel(obj)
            % ...
        end

        function onError(obj, exception)
            % ...
        end
    end
end
```
3. Create AsyncTask object with worker instance:
```matlab
worker = MessageWorker();
task = AsyncTask.forWorker(worker);
```
4. Optionally specify callback functions to get notified of worker events:
```matlab
task.eachDataCallback = @(data) disp(['Data received: ' data]);
task.taskDoneCallback = @(result) disp(['Result returned: ' result]);
task.taskFailedCallback = @(error) disp(['Error occurred: ' error]);
```
5. Start task with proper arguments:
```matlab
task.start('Blah');
```
6. To exchange data between client and worker use `pollData` and `sendData` methods:
```matlab
% on client side
task.sendData('From client to worker');

% on worker side
function onStart(obj)
    if obj.isDataAvailable()
        data = obj.pollData();
        disp(['Data from client received: ' data]);
        obj.sendData('Message handled');
    end
end
```
