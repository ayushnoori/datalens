#' The application User-Interface
#' 
#' @param request Internal parameter for `{shiny}`. 
#'     DO NOT REMOVE.
#' @import shiny argonDash
#' @noRd
app_ui <- function(request) {
  tagList(
    # Leave this function for adding external resources
    golem_add_external_resources(),
    
    # shiny fluid page
    fluidPage(
      title = "Alzheimer DataLENS",
      sidebarLayout(
        
        # sidebar with input
        sidebarLayout(
          
        ),
        
        mainPanel(
          
        )
        
      )
    )
    
    # # application UI logic
    # argonDashPage(
    #   title = "Alzheimer DataLENS",
    #   author = "Ayush Noori",
    #   description = "-Omics Data Analysis Platform for Alzheimer’s Disease Research",
    #   sidebar = argonSidebar,
    #   navbar = argonNav, 
    #   header = argonHeader,
    #   body = argonDashBody(
    #     argonTabItems(
    #       # cards_tab,
    #       # tables_tab,
    #       # tabsets_tab,
    #       # alerts_tab,
    #       # images_tab,
    #       # items_tab,
    #       # effects_tab,
    #       # sections_tab
    #     )
    #   )
    # )
    
    
  )
}

#' Add external Resources to the Application
#' 
#' This function is internally used to add external 
#' resources inside the Shiny application. 
#' 
#' @import shiny
#' @importFrom golem add_resource_path activate_js favicon bundle_resources
#' @noRd
golem_add_external_resources <- function(){
  
  add_resource_path(
    'www', app_sys('app/www')
  )
 
  tags$head(
    favicon(),
    bundle_resources(
      path = app_sys('app/www'),
      app_title = 'DataLENS'
    )
    # Add here other external resources
    # for example, you can add shinyalert::useShinyalert() 
  )
}

