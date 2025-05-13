# Time Series Trap Guide

## Назначение
Обнаружение аномалий во временных рядах данных блокчейна

## Параметры
- `historicalData`: Массив исторических значений
- `collect()`: Собирает новые данные
- `shouldRespond()`: Анализирует данные на аномалии

## Пример использования
[traps.time_series]
path = "out/TimeSeriesTrap.sol/TimeSeriesTrap.json"
response_contract = "0x..."
