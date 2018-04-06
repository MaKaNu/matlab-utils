classdef StockWorker < AsyncWorker

    properties (Constant)
        pricesUpdateInterval = 60;
        stockApiCallTimeout = 60;
    end

    properties
        stockSymbol;
        stockApiUrl;
        stockPrices = [];
        lastUpdateTimestamp = datetime - seconds(StockWorker.pricesUpdateInterval);
    end

    methods
        function onStart(obj, stockSymbol)
            obj.stockSymbol = stockSymbol;
            obj.stockApiUrl = obj.buildStockApiUrl(stockSymbol);
            while true
                obj.updatePricesIfMinutePassed();
                obj.cutExcessivePrices();
                obj.handleIncomingData();
                pause(1);
            end
        end

        function onCancel(obj)
            message = strcat('Cancelled worker for stock: ', obj.stockSymbol);
            obj.sendData(struct('message', message));
        end

        function onError(obj, exception)
            message = strcat('Most recent stock prices are:', sprintf('  %.4f', obj.stockPrices));
            obj.sendData(struct('message', message));
        end
    end

    methods (Access = private)

        function url = buildStockApiUrl(obj, stockSymbol)
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

        function updatePricesIfMinutePassed(obj)
            secondsSinceUpdate = etime(datevec(datetime), datevec(obj.lastUpdateTimestamp));
            if secondsSinceUpdate > obj.pricesUpdateInterval
                nextPrice = obj.getLatestStockPrice();
                obj.stockPrices(end+1) = nextPrice;
                obj.lastUpdateTimestamp = datetime;
            end
        end

        function price = getLatestStockPrice(obj)
            apiResponse = obj.makeStockApiRequest();
            lastStockRecord = obj.responseToLastRecord(apiResponse);
            price = (str2num(lastStockRecord.x3_Low) + str2num(lastStockRecord.x2_High)) / 2;
        end

        function response = makeStockApiRequest(obj)
            options = weboptions;
            options.Timeout = obj.stockApiCallTimeout;
            response = webread(obj.stockApiUrl, options);
        end

        function record = responseToLastRecord(obj, response)
            recordsStruct = response.TimeSeries_1min_;
            recordsCells = struct2cell(recordsStruct);
            record = recordsCells{1};
        end

        function cutExcessivePrices(obj)
            if length(obj.stockPrices) > 10
                obj.stockPrices = obj.stockPrices(end-9:end);
            end
        end

        function handleIncomingData(obj)
            while obj.isDataAvailable()
                cash = obj.pollData();
                obj.validateInputData(cash);
                meanPrice = mean(obj.stockPrices);
                volume = floor(cash / meanPrice);
                result = struct('timestamp', datetime, 'stockSymbol', obj.stockSymbol, ...
                    'availableCash', cash, 'meanPrice', meanPrice, 'potentialVolume', volume);
                obj.sendData(result);
            end
        end

        function validateInputData(obj, data)
            if ~isnumeric(data) && length(data) ~= 1
                id = 'StockWorker:invalidInputData';
                message = 'Input data must be numeric and of length 1.';
                throw(MException(id, message));
            end
        end
    end
end