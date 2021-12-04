#' bulk_RNAseq UI Function
#'
#' @description A shiny module to view bulk RNA-seq data analysis.
#'
#' @param id,input,output,session Internal parameters for {shiny}.
#'
#' @noRd 
#'
#' @importFrom shiny NS tagList 
mod_bulk_RNAseq_ui <- function(id){
  ns <- NS(id)
  tagList(
 
  )
}
    
#' bulk_RNAseq Server Functions
#'
#' @noRd 
mod_bulk_RNAseq_server <- function(id){
  moduleServer( id, function(input, output, session){
    ns <- session$ns
    
    # connect to MongoDB collection
    
 
  })
}
    
## To be copied in the UI
# mod_bulk_RNAseq_ui("bulk_RNAseq_ui_1")
    
## To be copied in the server
# mod_bulk_RNAseq_server("bulk_RNAseq_ui_1")
