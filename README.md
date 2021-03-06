# IIS Scripts

A repository of IBM Information Server related scripts by Fernando Nunes (domusonline@gmail.com)

### Introdution

This repository contains some scripts that may be of interest to IBM IS suite of products.
Due to lack of time, very sparse documentation will be produced.
Currently only a list of scripts with a brief description is included.

### Distribution and license

These repository uses GPL V2 (unless stated in a specific script or folder). In short terms it means you can use the contents freely. If you change them and distribute the results, you must also make the "code" available (with the current contents this is redundant as the script is the code)- The full license text can be read here:

[http://www.gnu.org/licenses/old-licenses/gpl-2.0.html](http://www.gnu.org/licenses/old-licenses/gpl-2.0.html "GNU GPL V2")

### Disclaimer

These scripts are provided AS IS. No guaranties of any sort are provided. Use at your own risk<br/>
None of the scripts should do any harm to your environment.
Please test the scripts in non critical environments before putting them into production

### Support

As stated in the disclaimer section above, the scripts are provided AS IS. The author will not guarantee any sort of support.

Nevertheless the author is insterested in improving these scripts. if you find a bug or have some special need please contact the author and provide information that can help him fix the bug ordecide if the feature is relevant and can be added in a future version

### Structure

#### importCB

Contains a script that allows the mass import of copybooks into the IGC catalog as DataFiles. This requires the open source Java packages CB2CML and XALAN:
- http://cb2xml.sourceforge.net/
- https://xalan.apache.org/xalan-j/index.html

The files included are:
- importCB.sh
This is the script itself. The calling syntax is:  
Usage: importCB.sh -d <CB_DIR> -f <CB_TAB> [ -e <CB_EXT> ] [ -s <separator char> ]  
        CB_DIR : Folder where the copybook files exist  
        CB_TAB : File within the CB_DIR where the list of files to process is defined (see input_file_example.csv)  
        CB_EXT : Optional extension to append to the copybook name in the CB_TAB file  
  separator char : caracter to use as base file column separator. Default is space  
 
- AuthFile  
Example of a standard authfile to be used by istool

- cb2xml_extract_level.xsl  
XSLT to extract the COBOL "level"

- cb2xml.properties  
Empty file required by CB2XML

- cb2xml_to_csv_istool.xsl  
XSLT to conver the XML file generated by CB2XML to a CSV to be processed by istool

- clean_hogan.awk  
Very specific AWK script to clean up "Hogan" copybooks. If you don't know what Hogan is, ignore this and make sure the setting CLEANUP_HOGAN_FLAG in the importCB.sh script is set to "0"

- input_file_example.csv  
An example file to be used as input by the script. The first line is an head and should not be changed. The next lines should contain the data for each copybook to be processed

