# Getting Started with AI in Positron

There are two main AI tools that you can work with in Positron:

1. [Positron Assistant](https://positron.posit.co/assistant.html)
2. [Databot](https://positron.posit.co/databot.html)

This will mostly focus on the first.

## Install Positron

If you're new to it, the first step would be to install [Positron](https://positron.posit.co/), which you can do so here: https://positron.posit.co/download.html

## Positron Assistant

### 1. Enable Positron Assistant

Go to [this webpage](https://positron.posit.co/assistant.html) to set up Positron Assistant. You just have to enable a setting in the IDE. Once you restart, a robot icon will show up in the left hand sidebar.

![](chatpane.png)

## 2. Get your API key

More providers are being added, but the default option is to use [Anthropic](https://www.anthropic.com/). This means you need to purchase credits for [Claude](https://platform.claude.com/dashboard). Once you enter your card and choose a dollar amount of credits to purchase, you'll be able to access an API key.

## 3. Authenticate in Positron

Then go back to Positron and _Add Anthropic as Chat Provider_ (see screenshot above). Enter your API key and you should be connected.

![](authenticate.png)

## 4. Begin chatting with file context

The point of the chat being integrated in the IDE is that it can understand the context of the project you are working in. For example, suppose we're working with a `server.R` file for a Shiny app. In the screenshot below, if we have that file open in our IDE, it will automatically assume that we want it to know the context in that file. Other files can be added as well.

![](context.png)

Then we can ask a question about our code, suggestions, etc. (or anything else we want). In the screenshot below, we ask it to make cleaner column names for a table displayed in an app, and it gives the following output in the chat that we can implement if we wish.

![](prompt11.png)

## 5. Inline prompting

Another cool thing is that instead of only using the chat pane for getting code suggestions, etc., we can prompt from directly in our scripts. For example, suppose we have a particular line in our code we need help completing. We can right-click on that line, and click "Copilot" -> "Editor Inline Chat" (see screenshot below):

![](inlineprompt.png)

We can then enter a prompt to actually alter the code in the live script. In the example, the original line is a basic `renderTable` statement that gets altered so the column names are cleaner (see below):

![](inlinepromptfix.png)

The coolest part is that they designed this intelligently: it will _tentatively_ make the suggested changes, but requires you to accept them before actually altering your script. So you can always revert back if you don't like what it gave you.