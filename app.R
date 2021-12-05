# DataLENS 2.0
# Ayush Noori
# CS50 Final Project


# SETUP

# load libraries
library(shiny)
library(shinydashboard)
library(mongolite) # read from MongoDB database


# USER INTERFACE

# define user interface
ui = dashboardPage(
    skin = "purple",
    
    # define header
    dashboardHeader(title = "Alzheimer DataLENS"),
    
    # define sidebar
    dashboardSidebar(
        sidebarMenu(
            menuItem("Dashboard", tabName = "dashboard", icon = icon("dashboard")),
            menuItem("Widgets", tabName = "widgets", icon = icon("th"))
        )
    ),
    
    # define body
    dashboardBody(
        # link to CSS stylesheet
        tags$head(tags$link(rel = "stylesheet", type = "text/css", href = "custom.css")),
        tabItems(
            
            # DASHBOARD
            tabItem(tabName = "dashboard",
                    fluidRow(
                        box(
                            title = "Controls",
                            sliderInput("bins", "Number of bins:", min = 1, max = 50, value = 30)
                        ),
                        box(plotOutput("distPlot"))
                    )
            ),
            
            # WIDGETS
            tabItem(tabName = "widgets",
                    h2("Widgets tab content")
            )
        )
    )
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
shinyApp(ui = ui, server = server)