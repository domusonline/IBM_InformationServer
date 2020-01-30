<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0">
<xsl:param name="P_DATAFILE"/>
<xsl:param name="P_DATAFILE_DESCRIPTION"/>
<xsl:param name="P_DATAFILE_STRUCTURE"/>
<xsl:param name="P_DATAFILE_STRUCTURE_DESCRIPTION"/>
<xsl:param name="P_PATH"/>
<xsl:param name="P_HOST"/>
<xsl:param name="P_FOLDER"/>

<xsl:param name="hostName"/>
<xsl:output method="text" encoding="iso-8859-1" omit-xml-declaration="yes"/>
<xsl:template match="copybook">
<xsl:text>+++ Host - begin +++&#xa;</xsl:text>
<xsl:text>Name&#xa;</xsl:text>
<xsl:value-of select="$P_HOST"/><xsl:text>&#xa;</xsl:text>
<xsl:text>+++ Host - end +++&#xa;</xsl:text>
<xsl:text>+++ Data File - begin +++&#xa;</xsl:text>
<xsl:text>Name,Host,Folder,Description,Path&#xa;</xsl:text>
<xsl:value-of select="$P_DATAFILE"/>,<xsl:value-of select="$P_HOST"/>,<xsl:value-of select="$P_FOLDER"/>,<xsl:value-of select="$P_DATAFILE_DESCRIPTION"/>,<xsl:value-of select="$P_PATH"/><xsl:text>&#xa;</xsl:text>
<xsl:text>+++ Data File - end +++&#xa;</xsl:text>
<xsl:text>+++ Data File Structure - begin +++&#xa;</xsl:text>
<xsl:text>Name,Host,Data File,Path,Description&#xa;</xsl:text>
<xsl:value-of select="$P_DATAFILE_STRUCTURE"/>,<xsl:value-of select="$P_HOST"/>,<xsl:value-of select="$P_DATAFILE"/>,<xsl:value-of select="$P_PATH"/>,<xsl:value-of select="$P_DATAFILE_STRUCTURE_DESCRIPTION"/><xsl:text>&#xa;</xsl:text>
<xsl:text>+++ Data File Structure - end +++&#xa;</xsl:text>
<xsl:text>+++ Data File Field - begin +++&#xa;</xsl:text>
<xsl:text>Name,Host,Data File,Data File Structure,Path,Description,ODBC Type,Data Type,Native Type,Length,Minimum Length,Nullability,Fraction,Position&#xa;</xsl:text>
<xsl:apply-templates select="item"><xsl:with-param name="nivel" select="0"/></xsl:apply-templates>
<xsl:text>+++ Data File Field - end +++&#xa;</xsl:text>
</xsl:template>	
<xsl:template match="item">
<xsl:param name="nivel"/>
<xsl:if test="$nivel != 0">
<xsl:variable name="SIGN" select="substring(@picture,1,1)"/>
<xsl:value-of select="@name"></xsl:value-of>,<xsl:value-of select="$P_HOST"/>,<xsl:value-of select="$P_DATAFILE"/>,<xsl:value-of select="$P_DATAFILE_STRUCTURE"/>,<xsl:value-of select="$P_PATH"/>,Description<xsl:choose>
<xsl:when test="@numeric">
	<xsl:choose>
		<xsl:when test="@usage = 'computational'">
			<xsl:choose>
				<xsl:when test="@storage-length = 2">,SMALLINT,INT16,BINARY,<xsl:value-of select="@display-length"/>,0</xsl:when>
				<xsl:when test="@storage-length = 4">,INTEGER,INT32,BINARY,<xsl:value-of select="@display-length"/>,0</xsl:when>
				<xsl:when test="@storage-length = 8">,BIGINT,INT64,BINARY,<xsl:value-of select="@display-length"/>,0</xsl:when>
			</xsl:choose>
		</xsl:when>
		<xsl:when test="@usage = 'computational-3'">,DECIMAL,DECIMAL,DECIMAL,<xsl:value-of select="@display-length"/>,0</xsl:when>
		<xsl:otherwise>,DECIMAL,DECIMAL,DISPLAY_NUMERIC,<xsl:value-of select="@display-length"/>,0</xsl:otherwise>
	</xsl:choose>
</xsl:when>
<xsl:otherwise>
	<xsl:choose>
		<xsl:when test="@picture">,CHAR,STRING,CHARACTER,<xsl:value-of select="@display-length"/>,<xsl:value-of select="@display-length"/></xsl:when>
		<xsl:otherwise>,CHAR,STRING,GROUP,<xsl:value-of select="@storage-length"/>,<xsl:value-of select="@storage-length"/></xsl:otherwise>
	</xsl:choose>
</xsl:otherwise>
</xsl:choose>,FALSE<xsl:choose>
	<xsl:when test="@scale">,<xsl:value-of select="@scale"/></xsl:when>
	<xsl:otherwise>,0</xsl:otherwise>
</xsl:choose>,<xsl:value-of select="@position"/><xsl:text>&#xa;</xsl:text></xsl:if><xsl:apply-templates select="item"><xsl:with-param name="nivel" select="1"/></xsl:apply-templates></xsl:template></xsl:stylesheet>
