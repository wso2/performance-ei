<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="2.0" xmlns:m="http://services.samples/xsd" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
        
        <xsl:template match="*">
            <m:buyStocks>
                <xsl:for-each select="@* | node()">
                    <xsl:if test="symbol = 'IBM'">
                    <order><symbol>XYZ</symbol><buyerID>doe</buyerID><price>23.56</price><volume>8030</volume></order>
                    </xsl:if>
                </xsl:for-each>
            </m:buyStocks>
        </xsl:template>
    </xsl:stylesheet>