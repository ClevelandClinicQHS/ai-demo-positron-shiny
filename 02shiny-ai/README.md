# Integrating a data chat in Shiny

The example Shiny application ([here](app.R)) shows how you can actually implement AI functionality in your apps. In this case, by creating a toggle for the user to switch between "traditional" data filters or a natural language chat interface that both result in dynamic changes in the application's output. 

Two main R packages are highlighted:

1. [`ellmer`](https://ellmer.tidyverse.org/): The engine for interacting seemlessly with LLM's from R
2. [`querychat`](https://posit-dev.github.io/querychat/r/index.html): Setup and configuration for creating a chat interface and creating queries on your dataset

The beauty of [`querychat`](https://posit-dev.github.io/querychat/r/index.html) as a concept is that it takes advantage of what LLM's are good at without compromising data security. Instead of giving any raw data to the LLM (i.e., it _never_ sees raw data), it only passes metadata associated with the dataset (which you can thoroughly explain in the [system prompt](https://ellmer.tidyverse.org/articles/ellmer.html#what-is-a-prompt)) and generates SQL queries on your behalf in the background to power any returned results. Thus, you can ask questions about your dataset in natural language and have it dynamically change your app, so it _feels_ like the LLM is touching your data, but it isn't.