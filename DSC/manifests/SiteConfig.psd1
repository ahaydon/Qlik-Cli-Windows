@{
  AllNodes = 
  @(
    @{
      NodeName = "sense1";
      Central  = $true;
      Role     = "Proxy";
      Location = "GB"
    },

    @{
      NodeName = "sense2";
      Role     = "Engine";
      Location = "GB"
    },

    @{
      NodeName = "sense3";
      Role     = "Scheduler";
      Location = "GB"
    }
  );
  NonNodeData =
  @{
    Location =
    @(
      "GB",
      "US"
    );
    License =
    @{
      Serial = "";
      Control = "";
      Name = "";
      Organization = "";
      Lef = ""
    }
  }
}
