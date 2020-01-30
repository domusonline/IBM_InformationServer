<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0">
<xsl:output method="text" encoding="iso-8859-1" omit-xml-declaration="yes"/>
<xsl:template match="copybook">
<xsl:text>BEGIN {vPOS=0;vPOSANT}&#xa;</xsl:text>

<xsl:text>/^ *&lt;hosts_DataStore/ {&#xa;</xsl:text>
<xsl:text>gsub(/ name="/," storeType=\042COBOL FD\042 creationTool=\042Connector Access Service 11.5\042 name=\042",$0)&#xa;</xsl:text>
<xsl:text>print $0&#xa;</xsl:text>
<xsl:text>next&#xa;</xsl:text>
<xsl:text>}&#xa;</xsl:text>

<xsl:text>/^ *&lt;contains_DataCollection/ {&#xa;</xsl:text>
<xsl:text>gsub(/ name="/," subtype=\042TABLE\042 nameQuotingChar=\042\042 creationTool=\042COBOL File Definition\042 name=\042",$0)&#xa;</xsl:text>
<xsl:text>print $0&#xa;</xsl:text>
<xsl:text>next&#xa;</xsl:text>
<xsl:text>}&#xa;</xsl:text>

<xsl:apply-templates select="item"/>

<xsl:text>&#xa;{&#xa;print $0 }&#xa;</xsl:text>

</xsl:template>	

<xsl:template match="item">
<xsl:variable name="SIGN" select="substring(@picture,1,1)"/>
<xsl:text>/^ *&lt;contains_DataField.* name="</xsl:text><xsl:value-of select="@name"/><xsl:text>" / {&#xa;</xsl:text>
<xsl:text>gsub(/sequence/,"levelNumber=\042</xsl:text><xsl:value-of select="@level + 0"/><xsl:text>\042 isSigned=\042</xsl:text><xsl:choose><xsl:when test="$SIGN = 'S'">TRUE</xsl:when><xsl:otherwise>FALSE</xsl:otherwise></xsl:choose><xsl:text>\042 itemKind=\042</xsl:text><xsl:value-of select="@position"/><xsl:text>-</xsl:text><xsl:value-of select="@position + @storage-length - 1"/><xsl:text>\042 displaySize=\042</xsl:text><xsl:value-of select="@display-length"/><xsl:text>\042 sequence",$0)&#xa;</xsl:text>
<xsl:text>gsub(/ sequence="[0-9][0-9]*" /," sequence=\042"vPOS"\042 ",$0)&#xa;</xsl:text>
<xsl:text>vPOS=vPOS+1&#xa;</xsl:text>
<xsl:text>print $0&#xa;</xsl:text>
<xsl:text>next&#xa;</xsl:text>
<xsl:text>}&#xa;</xsl:text>
<xsl:apply-templates select="item"/></xsl:template></xsl:stylesheet>
