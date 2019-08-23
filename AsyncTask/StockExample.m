worker = StockWorker();
task = AsyncTask.forWorker(worker);
task.eachDataCallback = @dispResult;
task.taskFailedCallback = @dispException;
prompt = 'Enter YOUR API-Key: '; 
% You can get your own API key on this Website:
% https://www.alphavantage.co/support/#api-key
API_KEY = input(prompt,'s');
setenv('STOCK_API_KEY',API_KEY)

task.start('TWTR');

while true
    task.sendData(1e6);
    executeTimeConsumingOps();
end

function executeTimeConsumingOps()
    pause(65);
end

function dispResult(result)
    if isfield(result, 'message')
        disp(result.message);
    else
        resultString = '[%s] %s: potential volume for mean price %.4f$ and cash %.2f$ is %d.';
        disp(sprintf(resultString, result.timestamp, result.stockSymbol, ...
            result.meanPrice, result.availableCash, result.potentialVolume));
    end
end

function dispException(exception)
    disp(['Worker failed because: ' exception.message]);
end