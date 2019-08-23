task = AsyncTask.builder()...
    .onStart(@startVolumeCalculator)...
    .onCancel(@sendCancelMessage)...
    .onEachData(@dispResult)...
    .onTaskFailed(@dispException)...
    .build();
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

function startVolumeCalculator(worker, stockSymbol)
    initGlobals(stockSymbol);
    while true
        updatePricesIfMinutePassed();
        cutExcessivePrices();
        handleClientRequests(worker);
        pause(1);
    end
end

function sendCancelMessage(worker)
    worker.sendData(struct('message', ['Cancelled worker for stock: ' obj.stockSymbol]));
end

function dispResult(result)
    if isfield(result, 'message')
        disp(result.message);
    else
        resultString = '[%s] %s: potential volume for mean price %.4f$ and available cash %.2f$ is %d.';
        disp(sprintf(resultString, result.timestamp, result.stockSymbol, ...
            result.meanPrice, result.availableCash, result.potentialVolume));
    end
end

function dispException(exception)
    disp(['Worker failed because: ' exception.message]);
end

function initGlobals(symbol)
    global pricesUpdateInterval;
    pricesUpdateInterval = 60;
    global stockApiCallTimeout;
    stockApiCallTimeout = 60;
    global stockPrices;
    stockPrices = [];
    global lastUpdateTimestamp;
    lastUpdateTimestamp = datetime - seconds(pricesUpdateInterval);
    global stockSymbol;
    stockSymbol = symbol;
    global stockApiUrl;
    stockApiUrl = buildStockApiUrl(stockSymbol);
end

function url = buildStockApiUrl(stockSymbol)
    stockBaseUrl = 'https://www.alphavantage.co/query';
    stockFunction = 'TIME_SERIES_INTRADAY';
    stockInterval = '1min';
    stockApiKey = getenv('STOCK_API_KEY');
    url = strcat(stockBaseUrl, ...
        '?function=', stockFunction, ...
        '&symbol=', stockSymbol, ...
        '&interval=', stockInterval, ...
        '&apikey=', stockApiKey);
end

function updatePricesIfMinutePassed()
    global lastUpdateTimestamp;
    global pricesUpdateInterval;
    global stockPrices;
    secondsSinceUpdate = etime(datevec(datetime), datevec(lastUpdateTimestamp));
    if secondsSinceUpdate > pricesUpdateInterval
        nextPrice = getLatestStockPrice();
        stockPrices(end+1) = nextPrice;
        lastUpdateTimestamp = datetime;
    end
end

function price = getLatestStockPrice()
    apiResponse = makeStockApiRequest();
    lastStockRecord = responseToLastRecord(apiResponse);
    price = (str2num(lastStockRecord.x3_Low) + str2num(lastStockRecord.x2_High)) / 2;
end

function response = makeStockApiRequest()
    global stockApiCallTimeout;
    global stockApiUrl;
    options = weboptions;
    options.Timeout = stockApiCallTimeout;
    response = webread(stockApiUrl, options);
end

function record = responseToLastRecord(response)
    recordsStruct = response.TimeSeries_1min_;
    recordsCells = struct2cell(recordsStruct);
    record = recordsCells{1};
end

function cutExcessivePrices()
    global stockPrices;
    if length(stockPrices) > 10
        stockPrices = stockPrices(end-9:end);
    end
end

function handleClientRequests(worker)
    global stockPrices;
    global stockSymbol;
    while worker.isDataAvailable()
        cash = worker.pollData();
        validateInputData(cash);
        meanPrice = mean(stockPrices);
        volume = floor(cash / meanPrice);
        result = struct('timestamp', datetime, 'stockSymbol', stockSymbol, ...
            'availableCash', cash, 'meanPrice', meanPrice, 'potentialVolume', volume);
        worker.sendData(result);
    end
end

function validateInputData(data)
    if ~isnumeric(data) && length(data) ~= 1
        id = 'StockWorker:invalidInputData';
        message = 'Input data must be numeric and of length 1.';
        throw(MException(id, message));
    end
end