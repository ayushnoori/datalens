# DataLENS 2.0
# Ayush Noori
# CS50 Final Project


# SETUP

# load libraries
library(shiny)
library(shinydashboard) # dashboard layout
library(mongolite) # read from MongoDB database
library(ggplot2) # visualization
library(plotly) # interactive visualization
library(DT) # JS data tables
library(data.table) # data tables in R
library(purrr) # iterable functions
library(magrittr) # pipes
library(org.Hs.eg.db) # map human genes

# plotting theme
base_theme = theme_bw() + theme(
    axis.title = element_text(face = "bold", size = 12),
    legend.title = element_text(face = "bold", size = 12))


# MONGODB DATABASE

# connect to MongoDB database
# hostname localhost and port 27017 are default for local MongoDB connections
mongo_url = "mongodb://127.0.0.1:27017"
expression = mongo(collection = "expression", db = "datalens", url = mongo_url)
subject_expression = mongo(collection = "subject_expression", db = "datalens", url = mongo_url)
subject_covariates = mongo(collection = "subject_covariates", db = "datalens", url = mongo_url)


# create list of permissible genes, the full list is not queried to save time
# input_genes = expression$distinct("GeneSymbol")

# genes can be defined manually or reactively
# input_genes = c("GFAP", "IBA1", "MHC2", "TMEM119")


# USER INTERFACE

# define user interface
ui <- dashboardPage(
    skin = "purple",
    
    # define header
    dashboardHeader(title = "Alzheimer DataLENS"),
    
    # define sidebar
    dashboardSidebar(
        sidebarMenu(
            menuItem("Home", tabName = "home", icon = icon("home")),
            menuItem("Input Genes", tabName = "input", icon = icon("dna")),
            menuItem("Differential Expression", tabName = "expression", icon = icon("chart-bar")),
            menuItem("Subject Expression", tabName = "subject-expression", icon = icon("chart-bar")),
            menuItem("Network", tabName = "network", icon = icon("project-diagram"))
        )
    ),
    
    # define body
    dashboardBody(
        # link to CSS stylesheet
        tags$head(tags$link(rel = "stylesheet", type = "text/css", href = "custom.css")),
        tabItems(
            
            # HOME
            tabItem(tabName = "home",
                    fluidRow(
                        # wide about box
                        box(title = "About", status = "primary", solidHeader = TRUE, width = 8,
                            p("Alzheimer DataLENS is an open data analysis platform which aims to advance Alzheimer’s disease research by enabling the analysis, visualization, and sharing of -omics data. DataLENS houses bioinformatics pipelines for the analysis of -omics data on Alzheimer’s disease and related dementias as well as streamlined web interfaces which allow neuroscientists to browse and query the results of these analyses."),
                        ),
                        # narrow attribution box
                        box(title = "Attribution", status = "primary", solidHeader = TRUE, width = 4,
                            p("Alzheimer DataLENS was created by ", a("Ayush Noori", href = "mailto:anoori1@mgh.harvard.edu"), "for CS50 at Harvard College. DataLENS is an initiative of the ", a("MIND Data Science Lab", href = "https://www.massgeneral.org/neurology/research/mind-data-science-lab"), "in the MassGeneral Institute for Neurodegenerative Disease (MIND) at Massachusetts General Hospital.")
                        )
                    )
            ),
            
            # INPUT GENES
            tabItem(tabName = "input",
                    fluidRow(
                        box(
                            # select input gene
                            title = "Input Genes", status = "primary", solidHeader = TRUE, width = 4,
                            p("Please input the list of human genes which you would like to analyze below."),
                            textAreaInput("input_genes", label = "Gene List", value = "APP\nPSEN1\nGFAP\nTMEM119", height = "300px"),
                            # define list separator
                            radioButtons("input_sep", label = "Separator", inline = T,
                                         choices = c(Line = "\n", Comma = ",", Space = " ", Tab = "\t")),
                            # define input format
                            radioButtons("input_format", label = "Format", inline = T,
                                         choices = c(`Gene Symbol` = "SYMBOL", `Ensembl ID` = "ENSEMBL", `ENTREZ ID` = "ENTREZID", `UniProt ID` = "UNIPROT")),
                            # validate button
                            actionButton("validate_genes", "Validate Genes")
                        ),
                        column(width = 8,
                               # show validated genes as table
                               box(title = "Validated Genes", status = "success", solidHeader = TRUE, width = NULL,
                                   div(style = 'overflow-x: scroll', DT::DTOutput("valid_genes"))),
                               # show invalid genes as a comma-separated list
                               box(title = "Invalid Genes", status = "danger", solidHeader = TRUE, width = NULL,
                                   textOutput("invalid_genes"))
                               )
                    )
            ),
            
            # HUMAN EXPRESSION ANALYSIS
            tabItem(tabName = "expression",
                    fluidRow(
                        column(width = 4,
                               # select and show gene from validated list in previous tab
                               valueBoxOutput("value_gene", width = NULL),
                               box(title = "Select Gene", status = "primary", solidHeader = TRUE, width = NULL,
                                   p("Modify the gene list in Input Genes."),
                                   uiOutput("select_gene"),
                                   # uiOutput("expr_dataset"),
                                   # use server-side selectize input instead
                                   selectizeInput("expr_dataset", "Select Dataset", choices = NULL, multiple = T)
                                )
                        ),
                        # plot fold-change as interactive Plotly plot
                        box(title = "Fold-Change", width = 8, status = "warning", solidHeader = TRUE,
                            plotlyOutput("expr_plot"))
                    ),
                    fluidRow(
                        # show results of differential expression analyses as table
                        box(title = "Differential Expression Analyses", width = 12, status = "warning", solidHeader = TRUE,
                            div(style = 'overflow-x: scroll', DT::DTOutput("expr_table")))
                    )
            ),
            
            # SUBJECT EXPRESSION
            tabItem(tabName = "subject-expression",
                    fluidRow(
                        box(title = "Select Filters", status = "primary", solidHeader = TRUE, width = 4,
                            p("Modify the gene list in Input Genes."),
                        ),
                        box(title = "Network Plot", status = "warning", solidHeader = TRUE, width = 8
                        )
                    )
            ),
            
            # NETWORK
            tabItem(tabName = "network",
                    fluidRow(
                        box(title = "Select Genes", status = "primary", solidHeader = TRUE, width = 4,
                            p("Modify the gene list in Input Genes."),
                            uiOutput("select_network_genes")
                            ),
                        box(title = "Network Plot", status = "warning", solidHeader = TRUE, width = 8
                        )
                    )
            )
        )
    )
)


# SERVER LOGIC

# define server-side logic
server <- function(input, output, session) {
    
    # INPUT GENES
    
    # delay reaction until user presses validate button
    raw_genes = eventReactive(input$validate_genes, {
        genes_split = strsplit(input$input_genes, input$input_sep)[[1]]
        validate(need(length(genes_split) <= 10, "Please input fewer than 100 genes."),
                 need(length(genes_split) > 0, "Please input at least one valid gene."))
        genes_split
    })
    
    # map genes
    select_keys = c("SYMBOL", "ENTREZID", "GENENAME", "ENSEMBL", "GENETYPE") # , "GO", "UNIPROT"
    select_key_names = c("Symbol", "ENTREZ", "Gene", "Ensembl", "Type") # "GO", "UniProt"
    select_result = eventReactive(input$validate_genes, {
        try_select = tryCatch(expr = {
            select(org.Hs.eg.db, keys = raw_genes(), 
                   columns = select_keys, keytype = input$input_format,
                   multiVals = "first") %>%
                as.data.table() %>%
                setnames(select_keys, select_key_names) %>%
                setcolorder(select_key_names)},
        error = function(e) {
          data.table()  
        })
        validate(need(nrow(try_select) > 0, "No matches found."))
        try_select
    })
    
    # render output for valid genes table
    valid_genes = reactive(select_result()[!is.na(Gene), ])
    output$valid_genes =  DT::renderDT(valid_genes())
    output$invalid_genes = renderText(
        select_result()[is.na(Gene), .SD,
                        .SDcols = select_key_names[which(select_keys == input$input_format)]][[1]],
        sep = ", ")
    
    # render output for expression analysis page
    output$select_gene = renderUI(
        selectInput("expr_gene", "Select Gene of Interest", choices = valid_genes()[, Symbol]))
    
    # render value box for expression analysis page
    output$value_gene = renderValueBox(valueBox(input$expr_gene, subtitle = "Selected Gene", icon = icon("dna"), width = NULL))
    
    
    # HUMAN EXPRESSION ANALYSIS
    
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
    
    # # render select menu for dataset
    # output$expr_dataset = renderUI(
    #     selectizeInput("expr_dataset", "Select Dataset",
    #                 choices = expr_dat()$Dataset, multiple = T))
    
    # use server-side selectize instead
    observeEvent(expr_dat(), {
        updateSelectizeInput(session, "expr_dataset", choices = expr_dat()$Dataset, server = TRUE)
    })
    
    # render interactive plot of data set using Plotly
    output$expr_plot = renderPlotly({
        ggplotly(expr_dat() %>%
            .[Dataset %in% input$expr_dataset] %>%
            .[order(logFC)] %>%
            .[, Dataset := {make.unique(Dataset, sep = " #") %>% factor(., levels = .)}] %>%
            .[!duplicated(Dataset)] %>%
            ggplot(aes(x = Dataset, y = logFC, fill = P)) +
                geom_bar(stat = "identity", color = "black") +
                scale_fill_gradient(low = "#FF851B", high = "#9EA3B0") +
                labs(fill = "P-Value") +
                base_theme + theme(axis.text.x = element_blank()))
    })
    
    
    # NETWORK
    output$select_network_genes = renderUI({
        selectizeInput("network_genes", "Select Genes",
                       choices = valid_genes()[, Symbol], multiple = T)
    })
    
    
}


# RUN APPLICATION

# run the application
shinyApp(ui = ui, server = server)
