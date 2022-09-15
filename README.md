# ui-stresstest
A collection of implementations in different languages that test the performance of a simple UI scenario

## Test scenario
The scenario is simple but can be challenging for an implementation to run. It aims to simulate a situation were the UI is composed of a large number of elements and were it needs to updates because it state changed.

The large number of UI elements is represented as a grid of squares with different colors and the state change that requires the UI to constantly update is represented by a squares that moves above the grid. The test scenario therefor does not try to optimize the fact that the background squares could be somehow cached into a single object. Implementations should also not try to find other quirky optimizations because the test should reflect a straight forward approach of having a typical UI with many independend views.

The screenshot shows how it should look for a 80*80 grid:
<img width="637" alt="Screenshot" src="https://user-images.githubusercontent.com/113168573/190328157-881166ca-0620-46e4-ad08-f8e018c82051.png">

## Available implementations
Currently there are implementations for SwiftUI, Objective C + Metal and HTML + CSS + JS.

The Metal implementation can be used as the baseline, it runs fast with a low CPU usage. SwiftUI is not so efficient but still runs smooth. The performance of the HTML implementation depends on the browser, it is very efficient in Safari but causes a higher CPU load in Google Chrome.

More detailed performance results will come soon.

