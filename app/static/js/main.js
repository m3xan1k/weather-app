const btn = document.querySelector("#btn");
const forecastDiv = document.querySelector("#forecast");


async function getForecast() {
    const response = await fetch("http://77.87.205.78/forecast");
    const forecast = await response.json();
    return forecast
}

function renderForecastItem(item) {
    return `<div class="ascii-table">
                <table>
                    <tr>
                        <img src="${item.icon_url}">
                    </tr>
                    <tr>
                        <td>Time</td>
                        <td>${item.time.slice(0, -3)}</td>
                    </tr>
                    <tr>
                        <td>Weather</td>
                        <td>${item.weather}</td>
                    </tr>
                    <tr>
                        <td>Temperature</td>
                        <td>${item.temp}</td>
                    </tr>
                    <tr>
                        <td>Humidity</td>
                        <td>${item.humidity}%</td>
                    </tr>
                    <tr>
                        <td>Wind</td>
                        <td>${item.wind}</td>
                    </tr>
                    <tr>
                        <td>Pressure</td>
                        <td>${item.pressure}</td>
                    </tr>
                </table>
            </div>`
}

function renderForecast(forecast) {
    const city = forecast.city;

    const markupList = forecast.list.map(item => renderForecastItem(item));
    const markup = markupList.join("");
    return markup
}

function process() {
    getForecast()
        .then(forecast => {
            forecastDiv.innerHTML = renderForecast(forecast);
        })
}

btn.addEventListener("click", process);