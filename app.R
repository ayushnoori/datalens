# DataLENS 2.0
# Ayush Noori
# CS50 Final Project


# SETUP

# load libraries
library(shiny)
library(shinydashboard) # dashboard layout
library(mongolite) # read from MongoDB database
library(ggplot2) # visualization
library(DT) # JS data tables
library(data.table) # data tables in R
library(purrr) # iterable functions
library(magrittr) # pipes

# plotting theme
base_theme = theme_bw() + theme(
    axis.title = element_text(face = "bold", size = 12),
    legend.title = element_text(face = "bold", size = 12))


# MONGODB DATABASE

# connect to MongoDB database
# hostname localhost and port 27017 are default for local MongoDB connections
mongo_url = "mongodb://127.0.0.1:27017"
expression = mongo(collection = "expression", db = "datalens", url = mongo_url)

# create list of permissible genes, the full list is not queried to save time
# genes = expression$distinct("GeneSymbol")
genes = c("GFAP", "IBA1", "MHC2", "TMEM119")


# USER INTERFACE

# define user interface
ui <- dashboardPage(
    skin = "purple",
    
    # define header
    dashboardHeader(title = "Alzheimer DataLENS"),
    
    # define sidebar
    dashboardSidebar(
        sidebarMenu(
            menuItem("Expression Analysis", tabName = "expression", icon = icon("chart-bar")),
            menuItem("Widgets", tabName = "widgets", icon = icon("th"))
        )
    ),
    
    # define body
    dashboardBody(
        # link to CSS stylesheet
        tags$head(tags$link(rel = "stylesheet", type = "text/css", href = "custom.css")),
        tabItems(
            
            # EXPRESSION ANALYSIS
            tabItem(tabName = "expression",
                    fluidRow(
                        box(
                            title = "Select Gene",
                            selectInput("expr_gene", "Select Gene of Interest", choices = genes),
                            uiOutput("select_expr"),
                            width = 4
                        ),
                        box(title = "Fold-Change",
                            plotOutput("expr_plot"),
                            width = 8)
                    ),
                    fluidRow(
                        box(
                            title = "Differential Expression Analysis",
                            div(style = 'overflow-x: scroll', DT::DTOutput("expr_table")),
                            width = 12)
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
    
    # EXPRESSION ANALYSIS
    
    # columns to filter
    expr_cols = c("FileName", "ProbeID", "logFC", "PValue", "adjPVal", "t", "AveExpr")
    numeric_cols = c("logFC", "PValue", "adjPVal", "t", "AveExpr")
    expr_col_names = c("Dataset", "Probe ID", "logFC", "P", "adj P", "t", "Ave. Expr.")
    
    # query expression collection using gene input
    # run expression$index() to view indexes
    expr_dat = reactive({
        expr_mat = expression$find(paste0('{"GeneSymbol" : "', input$expr_gene, '"}'))
        validate(need(nrow(expr_mat) > 0, "No results available for this gene."))
        expr_mat %>%
            as.data.table() %>%
            .[, .SD, .SDcols = expr_cols] %>%
            .[order(PValue)] %>%
            .[, FileName := gsub("(_)|(.csv)", " ", FileName)] %>%
            .[, (numeric_cols) := map(.SD, ~round(as.numeric(.x), 7)), .SDcols = numeric_cols] %>%
            setnames(expr_cols, expr_col_names)
    })
    
    # render data table
    output$expr_table = DT::renderDT(expr_dat())
    
    # render select menu for dataset
    output$select_expr = renderUI(selectInput("expr_dataset", "Select Dataset",
                                              choices = expr_dat()$Dataset, multiple = T, selectize = T))
    
    # render plot of dataset
    output$expr_plot = renderPlot(
        expr_dat() %>%
            .[Dataset %in% input$expr_dataset] %>%
            .[order(logFC)] %>%
            .[!duplicated(Dataset)] %>%
            ggplot(aes(x = Dataset, y = logFC, fill = P)) +
                geom_bar(stat = "identity", color = "black") +
                scale_fill_gradient(low = "#DD4B39", high = "#00C0EF") +
                base_theme
    )
    
    
}


# RUN APPLICATION

# run the application
shinyApp(ui = ui, server = server)