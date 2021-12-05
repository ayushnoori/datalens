# DataLENS 2.0
# Ayush Noori
# CS50 Final Project


# SETUP

# load libraries
library(shiny)
library(mongolite) # read from MongoDB database


# USER INTERFACE

# define user interface
ui <- htmlTemplate("index.html",
                   button = actionButton("action", "Action"),
                   slider = sliderInput("x", "X", 1, 100, 50)
)

# SERVER LOGIC

# define server-side logic
server <- function(input, output) {
    
    # connect to MongoDB database
    # hostname localhost and port 27017 are default for local MongoDB connections
    mongo_url = "mongodb://127.0.0.1:27017"
    expression = mongo(collection = "expression", db = "datalens", url = mongo_url)
    
    
    
    output$distPlot <- renderPlot({
        # generate bins based on input$bins from ui.R
        x <- faithful[, 2]
        bins <- seq(min(x), max(x), length.out = input$bins + 1)
        
        # draw the histogram with the specified number of bins
        hist(x, breaks = bins, col = 'darkgray', border = 'white')
    })
}


# RUN APPLICATION

# run the application 
shinyAppDir(ui = ui, server = server)