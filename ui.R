# Alzheimer DataLENS
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
      menuItem("Interaction Network", tabName = "network", icon = icon("project-diagram")),
      menuItem("Regional Expression", tabName = "regional-expression", icon = icon("brain"))
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
                box(title = "About DataLENS", status = "primary", solidHeader = TRUE, width = 8,
                    tags$p("Alzheimer DataLENS is an open data analysis platform which aims to advance Alzheimer’s disease research by enabling the analysis, visualization, and sharing of -omics data. DataLENS houses bioinformatics pipelines for the analysis of -omics data on Alzheimer’s disease and related dementias as well as streamlined web interfaces which allow neuroscientists to browse and query the results of these analyses."),
                ),
                # narrow attribution box
                box(title = "Attribution", status = "warning", solidHeader = TRUE, width = 4, collapsible = T, collapsed = F,
                    tags$p("Alzheimer DataLENS was created by ", tags$a("Ayush Noori", href = "mailto:anoori1@mgh.harvard.edu"), "for ", tags$a("CS50 at Harvard College", href = "https://cs50.harvard.edu/", target = "blank", rel = "noopener noreferrer"), ". DataLENS is an initiative of the ", tags$a("MIND Data Science Lab", href = "https://www.massgeneral.org/neurology/research/mind-data-science-lab", target = "blank", rel = "noopener noreferrer"), "in the MassGeneral Institute for Neurodegenerative Disease (MIND) at Massachusetts General Hospital.")
                )
              ),
              fluidRow(
                box(title = "How to Use", status = "warning", solidHeader = TRUE, width = 5,
                    tags$p("Interested in exploring DataLENS? Please follow the steps below:"),
                    tags$ol(
                      tags$li("Input a list of genes to ", tags$span(style = "font-style: italic;", "Input Genes,"), "then validate the gene set to confirm that all identifiers are found."),
                      tags$li("In ", tags$span(style = "font-style: italic;", "Differential Expression Analysis,"), " select a gene of interest. Observe how the expression levels of this gene changes in Alzheimer's disease and related dementias."),
                      tags$li("In ", tags$span(style = "font-style: italic;", "Interaction Network,"), "select genes of interest. Investigate interactions between these genes in the cellular interactome."),
                      tags$li("In ", tags$span(style = "font-style: italic;", "Regional Expression,"), "explore transcriptomic datasets across brain regions.")
                    )),
                box(title = "Alzheimer's Disease", status = "primary", solidHeader = TRUE, width = 7,
                    tags$p("Alzheimer's disease (AD) is a progressive neurodegenerative disorder which impairs memory and cognition, and for which there is currently no effective treatment nor cure."),
                    tags$ul(
                      tags$li("More than 6 million Americans live with AD today; in the absence of research advances, this number is projected to rise to 13 million by 2050."),
                      tags$li("1 in 3 seniors will die with Alzheimer's disease or another dementia, more than breast cancer and prostate cancer combined. Further, during the COVID-19 pandemic, isolation and neglect of the vulnerable elderly caused deaths from Alzheimer's and other dementias to rise by 16%."),
                      tags$li("In 2021, Alzheimer's disease and related dementias will cost the U.S. economy $355 billion; by 2050, this cost could rise to $1.1 trillion. In addition, more than 11 million Americans provided 15.3 billion hours of unpaid care for people with Alzheimer's and other dementias in 2020 ― this labor is valued at nearly $257 billion. Importantly, these statistics fail to account for the emotional toll on families and caregivers.")
                    ),
                    footer = tags$p(tags$strong("Source: "), tags$a(tags$span(style = "font-style: italic;", "Alzheimer's Disease Facts and Figures,"), "Alzheimer's Association 2021", href = "https://www.alz.org/alzheimers-dementia/facts-figures", target = "blank", rel = "noopener noreferrer", style = "color: black; text-decoration: none;"))
                )
              )
      ),
      
      # INPUT GENES
      tabItem(tabName = "input",
              fluidRow(
                box(
                  # select input gene
                  title = "Input Genes", status = "primary", solidHeader = TRUE, width = 5,
                  tags$p("Please input the list of human genes which you would like to analyze below. Validate the gene set using", tags$a("genome-wide human annotations", href = "https://www.bioconductor.org/packages/release/data/annotation/html/org.Hs.eg.db.html", target = "blank", rel = "noopener noreferrer"), "to confirm that all identifiers are found. The following identifiers are accepted: HGNC symbol, Ensembl ID, ENTREZ ID, and UniProt ID."),
                  textAreaInput("input_genes", label = "Gene List",
                                value = "APOE\nAPP\nAQP1\nAQP4\nBACE1\nC3\nCD44\nCD68\nCHI3L1\nCRYAB\nGFAP\nGLUL\nIL18\nIL1B\nMAPT\nPSEN1\nRELA\nTMEM119\nTNF\nTP53\nTSPO\nVIM",
                                height = "300px"),
                  # define list separator
                  radioButtons("input_sep", label = "Separator", inline = T,
                               choices = c(Line = "\n", Comma = ",", Space = " ", Tab = "\t")), # Auto = "auto" for auto-delimiting
                  # define input format
                  radioButtons("input_format", label = "Identifier", inline = T,
                               choices = c(Symbol = "SYMBOL", Ensembl = "ENSEMBL", ENTREZ = "ENTREZID", UniProt = "UNIPROT")),
                  # validate button
                  # div(class = "btn-div", actionButton("validate_genes", arrow_button("Validate Genes")))
                  tags$div(class = "btn-div", actionButton("validate_genes", "Validate Genes"))
                ),
                column(width = 7,
                       # show validated genes as table
                       box(title = "Validated Genes", status = "success", solidHeader = TRUE, width = NULL,
                           tags$div(style = 'overflow-x: auto', DT::DTOutput("valid_genes"))),
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
                           tags$p("Using the validated gene set from", tags$span(style = "font-style: italic;", "Input Genes,"), " explore the expression levels of a gene of interest in various transcriptomic studies below. For any given gene, expression levels [i.e., log(fold-change) and p-value] across multiple datasets can be compared."),
                           uiOutput("select_gene"),
                           # uiOutput("expr_dataset"),
                           # use server-side selectize input instead
                           selectizeInput("expr_dataset", "Select Dataset", choices = NULL, multiple = T)
                       )
                ),
                # plot fold-change as interactive Plotly plot
                box(title = "Study Comparison", width = 8, status = "warning", solidHeader = TRUE,
                    plotlyOutput("expr_plot"))
              ),
              fluidRow(
                # show results of differential expression analyses as table
                box(title = "Differential Expression Analyses", width = 12, status = "warning", solidHeader = TRUE,
                    tags$div(style = 'overflow-x: auto', DT::DTOutput("expr_table")))
              )
      ),
      
      
      # NETWORK
      tabItem(tabName = "network",
              fluidRow(
                column(width = 4,
                  box(title = "Select Genes", status = "primary", solidHeader = TRUE, width = NULL,
                      tags$p("Using the validated gene set from", tags$span(style = "font-style: italic;", "Input Genes,"), " explore relationships between these genes in the ", tags$a("STRING database", href = "https://string-db.org/", target = "blank", rel = "noopener noreferrer"), " of known and predicted protein-protein interactions (PPIs)."),
                      uiOutput("select_network_genes"),
                      # generate network button
                      tags$div(class = "btn-div", actionButton("generate_network", "Generate Network"))
                  ),
                  box(title = "Select Study", status = "primary", solidHeader = TRUE, width = NULL,
                      tags$p("Select a differential expression analysis of interest below. Nodes in the PPI network will be colored according to fold-change in that dataset and scaled according to significance, while edge width represents the combined score of evidence for interaction between two nodes."),
                      uiOutput("select_network_study"),
                      uiOutput("select_network_region"),
                      uiOutput("select_network_contrast"),
                      uiOutput("select_network_analysis"),
                      # generate network button
                      tags$div(class = "btn-div", actionButton("update_network", "Update Network"))
                  )
                ),
                box(title = "Network Plot", status = "warning", solidHeader = TRUE, width = 8,
                    # textOutput("network_warning"),
                    girafeOutput("network_plot")
                )
              )
      ),
      
      
      # REGIONAL EXPRESSION
      tabItem(tabName = "regional-expression",
              fluidRow(
                box(title = "Select Brain Region", status = "primary", solidHeader = TRUE, width = 4,
                    # tags$p("Using the validated gene set from", tags$span(style = "font-style: italic;", "Input Genes,"), " explore the expression levels of a gene of interest in specific brain regions."),
                    # uiOutput("select_region_gene"),
                    tags$p("Explore transcriptomic datasets across various brain regions by selecting region(s) of interest below."),
                    uiOutput("select_region")
                ),
                box(title = "Brain Regions", status = "warning", solidHeader = TRUE, width = 8,
                    tags$div(plotOutput("dk_plot"), style = "width: 49%; display: inline-block;"),
                    tags$div(plotOutput("aseg_plot"), style = "width: 49%; display: inline-block;")
                )),
              fluidRow(
                box(title = "Datasets", status = "warning", solidHeader = TRUE, width = 12,
                    tags$div(style = 'overflow-x: auto', DT::DTOutput("region_table"))
                )
              )
      )
    )
  )
)
