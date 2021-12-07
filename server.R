# Alzheimer DataLENS
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
library(ggseg) # brain visualization
library(igraph) # graph representation
library(ggraph) # graph plotting
library(ggiraph) # interactive graph plotting

# log the reactive graph
# library(reactlog)

# plotting theme
base_theme = theme_bw() + theme(
  axis.title = element_text(face = "bold", size = 12),
  legend.title = element_text(face = "bold", size = 12))


# MONGODB DATABASE

# connect to MongoDB database
# hostname localhost and port 27017 are default for local MongoDB connections
mongo_url = "mongodb://127.0.0.1:27017"
main = mongo(collection = "main", db = "datalens", url = mongo_url)
expression = mongo(collection = "expression", db = "datalens", url = mongo_url)

# the following two collections are excluded to comply with Data Use Agreements
# subject_expression = mongo(collection = "subject_expression", db = "datalens", url = mongo_url)
# subject_covariates = mongo(collection = "subject_covariates", db = "datalens", url = mongo_url)


# SERVER LOGIC

# define server-side logic
server <- function(input, output, session) {
  
  # BASELINE QUERIES
  
  # first, queries which are non-reactive (i.e., always must be made) are performed
  message("Querying MongoDB database, main collection")
  all_datasets = main$find() %>% as.data.table() # get all datasets
  
  
  # INPUT GENES
  
  # delay reaction until user presses validate button
  raw_genes = eventReactive(input$validate_genes, {
    
    # could adapt for auto-delimiting in the future
    delim = input$input_sep
    
    # split genes
    genes_split = unique(strsplit(input$input_genes, delim)[[1]])
    genes_split
    
  })
  
  # validate input genes by mapping to human database
  select_keys = c("SYMBOL", "ENTREZID", "GENENAME", "ENSEMBL", "GENETYPE") # , "GO", "UNIPROT"
  select_key_names = c("Symbol", "ENTREZ", "Gene", "Ensembl", "Type") # "GO", "UniProt"
  select_result = eventReactive(input$validate_genes, {
    
    # first, validate input
    validate(need(length(raw_genes()) <= 100, "Please input fewer than 100 genes."),
             need(length(raw_genes()) > 0, "Please input at least one valid gene."))
    
    # try/catch in case no mappings are found
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
    
    # validate try/catch
    validate(need(nrow(try_select) > 0, "No matches found."))
    try_select
  })
  
  # render output for valid genes table
  valid_genes = reactive(select_result()[!is.na(Gene), ])
  output$valid_genes =  DT::renderDT(valid_genes())
  
  # render output for invalid genes list
  output$invalid_genes = renderText({
    # select invalid genes, if any
    invalid_text = select_result()[is.na(Gene), .SD, .SDcols = select_key_names[which(select_keys == input$input_format)]][[1]]
    # check if any invalid genes
    if(length(invalid_text) == 0) invalid_text = "No invalid genes."
    invalid_text
  }, sep = ", ")
  
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
    message("Querying MongoDB database, expression collection")
    expr_mat = expression$find(paste0('{"GeneSymbol" : "', input$expr_gene, '"}')) # database query
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
  
  
  # INTERACTION NETWORK ANALYSIS
  
  # hierarchy of filters is as follows:
  # study > brain region > comparison > analysis > gene
  
  # render gene selector
  output$select_network_genes = renderUI({
    selectizeInput("network_genes", "Select Genes",
                   choices = valid_genes()[, Symbol], multiple = T)
  })
  
  # render study selector
  output$select_network_study = renderUI({
    selectizeInput("network_study", "Select Study",
                   choices = all_datasets[, unique(StudyName)], multiple = F,
                   selected = "ROSMAP")
  })
  
  # render brain region selector
  output$select_network_region = renderUI({
    selectizeInput("network_region", "Select Brain Region",
                   choices = all_datasets[StudyName %in% input$network_study, unique(BrainRegionFull)], multiple = T,
                   selected = "Dorsolateral Prefrontal Cortex")
  })
  
  # render comparison selector
  output$select_network_contrast = renderUI({
    selectizeInput("network_contrast", "Select Contrast",
                   choices = all_datasets[StudyName %in% input$network_study & BrainRegionFull %in% input$network_region, unique(Contrast)], multiple = T,
                   selected = "B3-B1")
  })
  
  # render analysis selector
  output$select_network_analysis = renderUI({
    
    possible_analyses = all_datasets[StudyName %in% input$network_study & BrainRegionFull %in% input$network_region & Contrast %in% input$network_contrast, FileName]
    names(possible_analyses) = gsub("(_)|(.csv)", " ", possible_analyses)
    
    selectizeInput("network_analysis", "Select Analysis",
                   choices = possible_analyses, multiple = F,
                   selected = "ROSMAP_PFC_Braak_B3-B1.csv")
    
  })
  
  # STRING API call to get network
  net = eventReactive(input$generate_network, {
    
    # check if genes are sufficient
    validate(need(length(input$network_genes) > 0, "Please select at least one valid gene."))
    
    # construct POST request
    # example of input$network_genes: c("GFAP", "APP", "TMEM119", "CHI3L1", "PSEN1")
    root_api = "https://version-11-0b.string-db.org/api"
    get_network = list(identifiers = paste(input$network_genes, collapse = "%0d"),
                       species = "9606", echo_query = "1", caller_identity = "DataLENS")
    
    # complete API call to retrieve network
    network_request = httr::POST(url = paste0(root_api, "/tsv/network"), body = get_network)
    message("Making POST request to STRING database")
    network = httr::content(network_request, as = "text", encoding = "UTF-8") %>%
      fread() %>%
      .[, c("stringId_A", "stringId_B", "ncbiTaxonId") := NULL] %>%
      unique()
    
  })
  
  # # inform user if they have not yet selected a dataset
  # output$network_warning = eventReactive(input$generate_network, {
  #   validate(need(nrow(network_query() > 0), "Please select a dataset of interest and update the graph."))
  #   ""
  # })
  
  # make updated query, using eventReactive() to minimize database calls
  network_query = eventReactive(input$update_network, {
    # note that the below line can be used in the MongoDB shell to construct an index on both GeneSymbol and FileName
    # db.expression.createIndex({ "GeneSymbol": 1, "FileName": 1 })
    # to just construct on FileName
    # db.expression.createIndex({ "FileName": 1 })
    
    # query database for fold-change and significance values in user-selected analysis
    # construct MongoDB query below, example of input$network_analysis: "ROSMAP_PFC_Braak_B3-B1.csv"
    message("Querying MongoDB database, expression collection")
    expression$find(paste0('{"FileName" : "', input$network_analysis, '"}'))
  })
  
  # show output
  net_graph = reactive({
    
    # construct network graph
    network_graph = graph_from_data_frame(d = net(), directed = FALSE)
    
    # get vertices
    network_vertices = vertex_attr(network_graph, "name") %>% factor(., levels = .)
    
    # parse network based on nodes
    validate(need(!is.null(network_query()), "Please select a dataset of interest and update the graph."))
    network_vals = network_query() %>% # database query
      as.data.table() %>%
      .[GeneSymbol %in% network_vertices] %>%
      .[order(AveExpr)] %>%
      .[!duplicated(GeneSymbol)] %>%
      # clean and remove unneeded columns
      .[, .SD, .SDcols = c("GeneSymbol", expr_cols)] %>%
      .[, FileName := gsub("(_)|(.csv)", " ", FileName)] %>%
      .[, (numeric_cols) := map(.SD, ~round(as.numeric(.x), 7)), .SDcols = numeric_cols] %>%
      setnames(c("GeneSymbol", expr_cols), c("name", expr_col_names)) %>%
      # set correct order to match with graph and fill in any missing vertices
      merge(data.table(name = network_vertices), ., all = T, sort = F) %>%
      .[is.na(logFC), c("logFC", "P") := .(0, 1)]
    
    # assign vertex attributes
    vertex_attr(network_graph) <- network_vals
    
    network_graph
  })
    
  # show output
  output$network_plot = renderGirafe({
    
    # toggle to change node size
    minmax = c(2, 10)
    
    # make static network plot with interactive parameter
    static_graph = ggraph(net_graph(), layout = "stress") + 
      geom_edge_link(aes(width = score), alpha = 0.4) +
      scale_edge_width(range = c(0.2, 0.9)) +
      geom_point_interactive(mapping = aes(x = x, y = y,
                                           tooltip = paste0(name, "\nlogFC: ", logFC, "\np-value: ", P),
                                           fill = logFC, size = -log10(P)),
                             shape = 21, color = "black") +
      scale_fill_gradient2_interactive(low = "#20A4F3", mid = "white", high = "#FF6B6B", midpoint = 0) +
      scale_size(range = minmax) +
      theme_graph(fg_text_colour = "black", base_family = "sans") + 
      labs(edge_width = "Score", fill = "logFC", size = "-log10(P)")
    
    # convert to interactive network plot
    girafe(ggobj = static_graph, options = list(
      opts_hover(css = "fill:#6006EA;stroke:black;cursor:pointer;", reactive = TRUE),
      opts_selection(type = "multiple", css = "fill:#6006EA;stroke:black;")
      ))
    
  })
  
  
  
  # REGIONAL EXPRESSION ANALYSIS
  # inspired by https://github.com/anniegbryant/DA5030_Final_Project
  
  # # construct brain region mapping
  # brain_regions = unique(all_datasets$BrainRegionFull) %>%
  #   data.table(Region = .) %>%
  #   .[order(Region)]
  
  # read manual mapping file constructed from the brain regions in the Desikan-Killany (dk) cortical atlas
  # and automatic subcortical segmentation atlas (aseg), remove bulk cortex
  brain_mapping = fread("www/assets/ggseg_mapping.csv")[!Region == "Cortex"]
  
  # # render selector for gene of interest
  # output$select_region_gene = renderUI(
  #   selectInput("region_gene", "Select Gene of Interest", choices = valid_genes()[, Symbol]))
  
  # render selector for brain region
  # output$select_region = renderUI(
  #   checkboxGroupInput("regions", "Select Brain Region", choices = brain_mapping$Region, inline = F))
  
  # render dropdown selector
  output$select_region = renderUI(
    selectizeInput("regions", "Select Brain Region", choices = brain_mapping$Region, multiple = T))
  
  # define theme for brain plots
  atlas_theme = theme(axis.text = element_blank(),
                      axis.title = element_blank(),
                      legend.position = "none")
  
  # plot dk atlas brain regions
  output$dk_plot = renderPlot({
    
    # get selected regions which correspond to the Desikan-Killany (dk) cortical atlas
    # example of input$regions: c("Amygdala", "Inferior Frontal Gyrus", "Frontal Pole", "Putamen", "Superior Temporal Gyrus")
    dk_regions = brain_mapping[Region %in% input$regions & Atlas == "dk", ]
    
    # save computation time if no regions are selected
    if(nrow(dk_regions) == 0) {
      
      dk_out = ggseg(atlas = "dk", fill = "#DAE0E7",
                     color = "white", position = "stacked") +
        atlas_theme
      
      # otherwise, search for and highlight selected regions
    } else {
      
      # check if atlas regions are in the vector of selected regions
      dk_data = as.data.table(dk$data) %>%
        .[, Selected := factor(ifelse(region %in% dk_regions$Mapping, "Yes", "No"), levels = c("Yes", "No"))] %>%
        .[, .(region, Selected)] %>%
        unique()
      
      # create brain segmentation plot
      dk_out = ggseg(dk_data, atlas = "dk", mapping = aes(fill = Selected),
                     color = "white", position = "stacked") +
        scale_fill_manual(values = c("#FF6B6B", "#DAE0E7"), na.value = "#DAE0E7") + 
        atlas_theme
      
    }
    
    dk_out
    
  })
  
  # plot aseg atlas brain regions
  output$aseg_plot = renderPlot({
    
    # get selected regions which correspond to the automatic subcortical segmentation atlas (aseg)
    aseg_regions = brain_mapping[Region %in% input$regions & Atlas == "aseg", ]
    
    # save computation time if no regions are selected
    if(nrow(aseg_regions) == 0) {
      
      aseg_out = ggseg(atlas = "aseg", fill = "#DAE0E7",
                       color = "white") +
        atlas_theme
      
      # otherwise, search for and highlight selected regions
    } else {
      
      # check if aseg atlas regions are in the vector of selected regions
      aseg_data = as.data.table(aseg$data) %>%
        .[, Selected := factor(ifelse(region %in% aseg_regions$Mapping, "Yes", "No"), levels = c("Yes", "No"))] %>%
        .[, .(region, Selected)] %>%
        unique()
      
      # create brain segmentation plot
      aseg_out = ggseg(aseg_data, atlas = "aseg", mapping = aes(fill = Selected), color = "white") +
        scale_fill_manual(values = c("#FF6B6B", "#DAE0E7"), na.value = "#DAE0E7") + 
        atlas_theme
      
    }
    
    aseg_out
    
  })
  
  # rename columns
  dataset_cols = c("BrainRegionFull", "StudyName", "DatasetCode", "StratFactor", "LabelGroupA", "LabelGroupB", "NGenes", "StudySynID")
  dataset_col_names = c("Region", "Study", "Code", "Factor", "Group 1", "Group 2", "No. Genes", "Reference")
  
  # create table for second tab
  output$region_table = renderDT({
    all_datasets %>%
      .[BrainRegionFull %in% input$regions] %>%
      .[, LabelGroupA := paste0(LabelGroupA, " (n=", NSubjectsGroupA, ")")] %>%
      .[, LabelGroupB := paste0(LabelGroupB, " (n=", NSubjectsGroupB, ")")] %>%
      .[, .SD, .SDcols = dataset_cols] %>%
      setnames(dataset_cols, dataset_col_names)
  })
  
  
}


# RUN APPLICATION

# log the reactive graph, do not enable in production!
# reactlog::reactlog_enable()

# run the application
# runApp()

# display reactive graph
# shiny::reactlogShow()