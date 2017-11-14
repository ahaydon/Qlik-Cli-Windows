function Get-QlikAbout {
  PROCESS {
    return Invoke-QlikGet "/qrs/about"
  }
}

function Get-QlikRelations {
  PROCESS {
    return Invoke-QlikGet "/qrs/about/api/relations"
  }
}
