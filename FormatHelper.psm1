function ConvertTo-FormatData
{
    [cmdletbinding()]
    param (
        [parameter(Mandatory=$true,ValueFromPipeline=$true)]
        $inputobject,

        [parameter()]
        [string[]]
        $property = '*',

        [parameter()]
        [switch]
        $ssitemmode
    );

    begin {
      $wildcards = $property | %{ new-object System.Management.Automation.WildcardPattern $_ }
      $controls = @();
      $views = @();  
      $booleanTypes = @(
        'bool','system.boolean'
      );
      $numericTypes = @(
        'byte','int16','int','float','double','decimal',
        'uint16','uint32','uint64', 
        'system.byte','system.int16','system,int32','system,int64',
        'system.uint16','system,uint32','system,uint64'
        );
    }
    
    process {

        function get-propertyType
        {
            process
            {
                $input.definition -replace '(^\S+).+','$1'
            }
        }
        
        $properties = $inputobject | get-member -MemberType Properties | where {$_.name -ne 'SSItemMode'} | where {
            $n = $_.name;
            write-debug "INPUT $n";
            $wildcards | where {
                write-debug "PATTERN $_"
                $_.IsMatch($n)
            }
        };
        
        if( -not $properties ) {
            return;
        }

        $typename = $inputobject.getType().Name;
        $fullTypeName = $inputobject.getType().FullName;

        $controls += @"
     <Control>
      <Name>$typename-GroupingFormat</Name>
      <CustomControl>
        <CustomEntries>
          <CustomEntry>
            <CustomItem>
              <Frame>
                <LeftIndent>4</LeftIndent>
                <CustomItem>
                  <Text>Location: </Text>
                  <ExpressionBinding>
                    <PropertyName>PSParentPath</PropertyName>
                  </ExpressionBinding>
                  $(
                  if( $ssitemmode ) {
                  '<NewLine/>
                  <Text>Available Operations: </Text>
                  <ExpressionBinding>
                    <ScriptBlock>(get-item `$_.PSParentPath).SSItemMode</ScriptBlock>
                  </ExpressionBinding>
                  <NewLine/>'
                  })
                </CustomItem>
              </Frame>
            </CustomItem>
          </CustomEntry>
        </CustomEntries>
      </CustomControl>
    </Control>
"@

        $headers = @();
        $rows = @();

        $properties | ForEach-Object {
            $name = $_.Name;
            $align = 'left';
            if( ($_ | get-propertyType ) -in $numericTypes) {
                $align = 'right';
            }
            elseif (($_ | get-propertyType ) -in $booleanTypes) {
                $align = 'center';
            }

            $header = @"
          <TableColumnHeader>
            <Label>$name</Label>
            <Alignment>$align</Alignment>
          </TableColumnHeader>
"@
            $row = @"
          <TableColumnItem>
            <PropertyName>$name</PropertyName>
          </TableColumnItem>
"@
            $headers += $header;
            $rows += $row;
    };

        $views += @"
    <View>
      <Name>$typename-View</Name>
      <ViewSelectedBy>
        <TypeName>$fullTypeName</TypeName>
      </ViewSelectedBy>
      <GroupBy>
        <PropertyName>PSParentPath</PropertyName>
        <CustomControlName>$typename-GroupingFormat</CustomControlName>
      </GroupBy>
      <TableControl>
        <TableHeaders>
        $(
              if($ssitemmode){
          '<TableColumnHeader>
            <Label>          </Label>
            <Alignment>Left</Alignment>
            <Width>10</Width>
          </TableColumnHeader>'
          })
            $($headers -join '')
        </TableHeaders>
        <TableRowEntries>
          <TableRowEntry>
            <TableColumnItems>
              $(
              if($ssitemmode){
              '<TableColumnItem>
                <PropertyName>SSItemMode</PropertyName>
              </TableColumnItem>'
              })
              $($rows -join '')
            </TableColumnItems>
          </TableRowEntry>
        </TableRowEntries>
      </TableControl>
    </View>
"@

    }

    end {
        [xml]@"
<Configuration>
  <Controls>
    $($controls -join '')
  </Controls>

  <ViewDefinitions>
    $($views -join '' )
  </ViewDefinitions>
</Configuration>
"@
    }
}