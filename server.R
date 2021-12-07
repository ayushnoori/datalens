# DataLENS 2.0
# Ayush Noori
# CS50 Final Project


# SETUP

# load base libraries
library(shiny)
library(shinydashboard) # dashboard layout

# load database libraries
library(mongolite) # read from MongoDB database
library(org.Hs.eg.db) # human gene annotation database
library(AnnotationDbi) # retrieve annotated human gene data
library(httr) # POST request

# load data manipulation libraries
library(data.table) # data tables in R
library(purrr) # iterable functions
library(magrittr) # pipes

# load data visualization libraries
library(ggplot2) # data visualization
library(plotly) # interactive data visualization
library(DT) # JS data tables
library(igraph) # graph representation
library(ggraph) # graph plotting
library(ggiraph) # interactive graph plotting

# log the reactive graph
library(reactlog)

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
      AnnotationDbi::select(org.Hs.eg.db, keys = raw_genes(), 
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
  output$value_gene = renderValueBox({
    # suppress generation of value box is no value is selected
    validate(need(!is.null(input$expr_gene), FALSE)) # fail with no message
    valueBox(input$expr_gene, subtitle = "Selected Gene", icon = icon("dna"), width = NULL)
  })
  
  
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
    # validate((need(input$expr_gene != "" & !is.null(input$expr_gene), "Please select at least one valid gene.")))
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
               scale_fill_gradient(low = "#FF6B6B", high = "#9EA3B0") +
               labs(fill = "P-Value") +
               base_theme + theme(axis.text.x = element_blank()))
  })
  
  
  # SUBJECT EXPRESSION ANALYSIS
  
  # query subjects by filters, etc.
  # query subject expression by subjects returned
  # forest plot
  
  
  # NETWORK
  
  # make selector
  output$select_network_genes = renderUI({
    selectizeInput("network_genes", "Select Genes",
                   choices = valid_genes()[, Symbol], multiple = T)
  })
  
  # STRING API call to get network
  net = eventReactive(input$generate_network, {
    
    # check if genes are sufficient
    validate(need(length(input$network_genes) > 0, "Please select at least one valid gene."))
    
    # construct POST request
    root_api = "https://version-11-0b.string-db.org/api"
    get_network = list(identifiers = paste(input$network_genes, collapse = "%0d"),
                       species = "9606", echo_query = "1", caller_identity = "DataLENS")
    
    # complete API call to retrieve network
    network_request = httr::POST(url = paste0(root_api, "/tsv/network"), body = get_network)
    network = httr::content(network_request, as = "text", encoding = "UTF-8") %>%
      fread() %>%
      .[, c("stringId_A", "stringId_B", "ncbiTaxonId") := NULL] %>%
      unique()
    
  })
  
  # show output
  output$network_plot = renderGirafe({
    
    # construct network graph
    network_graph = graph_from_data_frame(d = net(), directed = FALSE)
    
    # toggle to change node size
    minmax = c(1, 10)
    
    # make static network plot with interactive parameter
    static_graph = ggraph(network_graph, layout = "stress") + 
      geom_edge_link(aes(width = score), alpha = 0.4) +
      scale_edge_width(range = c(0.2, 0.9)) +
      geom_point_interactive(mapping = aes(x = x, y = y, tooltip = name),
                             size = 5) +
      # scale_size(range = minmax) +
      theme_graph(fg_text_colour = "black", base_family = "sans") + 
      labs(edge_width = "Score")
    
    # convert to interactive network plot
    girafe(ggobj = static_graph)
    
  })
  
}


# RUN APPLICATION

# log the reactive graph, do not enable in production!
# reactlog::reactlog_enable()

# run the application
# runApp()

# display reactive graph
# shiny::reactlogShow()