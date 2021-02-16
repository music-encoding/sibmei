ExtensionDialog "Dialog"
{
  Title "Choose Sibmei extensions to activate"
  X "138"
  Y "282"
  Width "205"
  Height "170"
  Controls
  {
    Text
    {
      Title "Available Sibmei extensions"
      X "1"
      Y "2"
      Width "100"
      Height "14"
    }
    ListBox
    {
      Title
      X "1"
      Y "15"
      Width "201"
      Height "60"
      ListVar "AvailableExtensions"
      AllowMultipleSelections "1"
      Value "SelectedExtensions"
    }
    Button
    {
      Title "Activate All Extensions"
      X "2"
      Y "77"
      Width "68"
      Height "14"
      Method "SelectAllExtensions"
    }
    Button
    {
      Title "Deactivate All Extensions"
      X "72"
      Y "77"
      Width "68"
      Height "14"
      Method "DeselectAllExtensions"
    }
    Text
    {
      Title "Highlighted extensions are active."
      X "1"
      Y "99"
      Width "204"
      Height "10"
    }
    Text
    {
      Title "To activate multiple extensions, use Ctrl+click on Windows/Cmd+click on Mac"
      X "1"
      Y "109"
      Width "205"
      Height "14"
    }
    Button
    {
      Title "Export"
      X "151"
      Y "129"
      Width "50"
      Height "14"
      DefaultButton "1"
      EndDialog "1"
    }
    Button
    {
      Title "Cancel"
      X "100"
      Y "129"
      Width "50"
      Height "14"
      EndDialog "0"
    }
  }
}
