# DataLENS 2.0
# Ayush Noori
# CS50 Final Project


# USER INTERFACE

# define function to return button HTML
arrow_button = function(label) {
  return(HTML(paste0("<span>", label, "</span>",
  "<svg xmlns='http://www.w3.org/2000/svg' fill='none' viewBox='0 0 74 74' height='20' width='20'>
    <circle stroke-width='3' stroke='white' r='35.5' cy='37' cx='37'></circle>
    <path fill='white' d='M25 35.5C24.1716 35.5 23.5 36.1716 23.5 37C23.5 37.8284 24.1716 38.5 25 38.5V35.5ZM49.0607 38.0607C49.6464 37.4749 49.6464 36.5251 49.0607 35.9393L39.5147 26.3934C38.9289 25.8076 37.9792 25.8076 37.3934 26.3934C36.8076 26.9792 36.8076 27.9289 37.3934 28.5147L45.8787 37L37.3934 45.4853C36.8076 46.0711 36.8076 47.0208 37.3934 47.6066C37.9792 48.1924 38.9289 48.1924 39.5147 47.6066L49.0607 38.0607ZM25 38.5L48 38.5V35.5L25 35.5V38.5Z'></path>
  </svg>")))
}

# define user interface
ui <- dashboardPage(
  skin = "purple", title = "Alzheimer DataLENS",
  
  # define header
  header = dashboardHeader(title = tags$img(id = "datalens-logo", src = "assets/logo-white.svg")),
  
  # define sidebar
  sidebar = dashboardSidebar(
    sidebarMenu(
      menuItem("Home", tabName = "home", icon = icon("home")),
      menuItem("Input Genes", tabName = "input", icon = icon("dna")),
      menuItem("Differential Expression", tabName = "expression", icon = icon("chart-bar")),
      menuItem("Subject Expression", tabName = "subject-expression", icon = icon("chart-bar")),
      menuItem("Interaction Network", tabName = "network", icon = icon("project-diagram"))
    )
  ),
  
  # define body
  body = dashboardBody(
    # link to CSS stylesheet
    tags$head(tags$link(rel = "stylesheet", type = "text/css", href = "css/custom.css")),
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
                  # div(class = "btn-div", actionButton("validate_genes", arrow_button("Validate Genes")))
                  div(class = "btn-div", actionButton("validate_genes", "Validate Genes"))
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
                    uiOutput("select_network_genes"),
                    # generate network button
                    div(class = "btn-div", actionButton("generate_network", "Generate Network"))
                ),
                box(title = "Network Plot", status = "warning", solidHeader = TRUE, width = 8,
                    girafeOutput("network_plot")
                )
              )
      )
    )
  )
)
