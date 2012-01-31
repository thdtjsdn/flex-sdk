////////////////////////////////////////////////////////////////////////////////
//
//  ADOBE SYSTEMS INCORPORATED
//  Copyright 2008 Adobe Systems Incorporated
//  All Rights Reserved.
//
//  NOTICE: Adobe permits you to use, modify, and distribute this file
//  in accordance with the terms of the license agreement accompanying it.
//
////////////////////////////////////////////////////////////////////////////////

package spark.primitives
{

import flash.display.DisplayObjectContainer;
import flash.display.Graphics;
import flash.display.Shape;
import flash.geom.Rectangle;
import flash.text.engine.EastAsianJustifier;
import flash.text.engine.ElementFormat;
import flash.text.engine.FontDescription;
import flash.text.engine.FontMetrics;
import flash.text.engine.Kerning;
import flash.text.engine.LineJustification;
import flash.text.engine.SpaceJustifier;
import flash.text.engine.TextBlock;
import flash.text.engine.TextElement;
import flash.text.engine.TextLine;
import flash.text.engine.TextLineValidity;

import mx.core.mx_internal;
import spark.primitives.supportClasses.TextGraphicElement;

[DefaultProperty("text")]

//--------------------------------------
//  Styles
//--------------------------------------

include "../styles/metadata/BasicTextLayoutFormatStyles.as"
include "../styles/metadata/NonInheritingTextLayoutFormatStyles.as"

[IconFile("SimpleText.png")]

/**
 *  A box, specified in the parent Group element's coordinate space, that contains text.
 *  
 *  <p>The SimpleText class is similar to the mx.controls.Label control, although it can display 
 *  multiple lines.</p>
 *  
 *  <p>SimpleText does not support drawing a background or border; it only renders text. It supports only the basic formatting styles.
 *  If you want to use more advanced formatting styles, use the RichText or RichEditableText control.</p> 
 *  
 *  <p>The specified text is wrapped at the right edge of the component's bounds. If it extends below the bottom, it is clipped.
 *  The display cannot be scrolled.</p>
 *  
 *  @see mx.components.RichEditableText
 *  @see mx.graphics.RichText
 *  
 *  @includeExample examples/SimpleTextExample.mxml
 *  
 *  @langversion 3.0
 *  @playerversion Flash 10
 *  @playerversion AIR 1.5
 *  @productversion Flex 4
 */
public class SimpleText extends TextGraphicElement
{
    include "../core/Version.as";

	//--------------------------------------------------------------------------
    //
    //  Class variables
    //
    //--------------------------------------------------------------------------
	    
    // We can re-use single instances of a few FTE classes over and over,
    // since they just serve as a factory for the TextLines that we care about.
    
    /**
	 *  @private
	 */
	private static var staticTextBlock:TextBlock = new TextBlock();

	/**
	 *  @private
	 */
	private static var staticTextElement:TextElement = new TextElement();

    /**
     *  @private
     */
    private static var staticSpaceJustifier:SpaceJustifier =
        new SpaceJustifier();

    /**
     *  @private
     */
    private static var staticEastAsianJustifier:EastAsianJustifier =
        new EastAsianJustifier();

    //--------------------------------------------------------------------------
    //
    //  Class methods
    //
    //--------------------------------------------------------------------------
    
    /**
     *  @private
     */
    private static function getNumberOrPercentOf(value:Object,
                                                 n:Number):Number
    {
        // If 'value' is a Number like 10.5, return it.
        if (value is Number)
            return Number(value);

        // If 'value' is a percentage String like "10.5%",
        // return that percentage of 'n'.
        if (value is String)
        {
            var len:int = String(value).length;
            if (len >= 1 && value.charAt(len - 1) == "%")
            {
                var percent:Number = Number(value.substring(0, len - 1));
                return percent / 100 * n;
            }
        }

        // Otherwise, return NaN.
        return NaN;
    }

    //--------------------------------------------------------------------------
    //
    //  Constructor
    //
    //--------------------------------------------------------------------------

    /**
     *  Constructor. 
     *  
     *  @langversion 3.0
     *  @playerversion Flash 10
     *  @playerversion AIR 1.5
     *  @productversion Flex 4
     */
    public function SimpleText()
    {
        super();
    }
    
    //--------------------------------------------------------------------------
    //
    //  Methods
    //
    //--------------------------------------------------------------------------

    /**
     *  @private
     */
    override protected function composeTextLines(width:Number = NaN,
												 height:Number = NaN):void
    {
        super.composeTextLines(width, height);
        
        var elementFormat:ElementFormat = createElementFormat();
            
		// Set the composition bounds to be used by createTextLines().
		// If the width or height is NaN, it will be computed by this method
		// by the time it returns.
		// The bounds are then used by the addTextLines() method
		// to determine the isOverset flag.
		// The composition bounds are also reported by the measure() method.
		var bounds:Rectangle = mx_internal::bounds;
        bounds.x = 0;
        bounds.y = 0;
        bounds.width = width;
        bounds.height = height;

        // Remove the text lines from the container.  If we're recycling the
        // text lines, leave them in mx_internal::textLines.
        mx_internal::removeTextLines();
        if (!recycleTextLines)
            mx_internal::textLines.length = 0;
            
		var createdAllLines:Boolean = createTextLines(elementFormat);
        
        // Need truncation if all the following are true
        // - truncation options exist (0=no trunc, -1=fill up bounds then trunc,
        //      n=n lines then trunc)
        // - compose width is specified
        // - explicit line breaking is not used
        // - content doesn't fit
        if (truncation && getStyle("lineBreak") == "toFit" &&
            !doesComposedTextFit(height, createdAllLines, truncation))
        {
            truncateText(width, height);
        }
        
        // Done with the lines now.  
        releaseLinesFromTextBlock(mx_internal::textLines);
        
        // If toFit and explicit width, adjust the bounds to match.
        // This will save a recompose and/or clip in updateDisplayList() if 
        // the bounds width matches the unscaled width.
        if (getStyle("lineBreak") == "toFit" && 
            !isNaN(width) && mx_internal::bounds.width < width)
        {
            mx_internal::bounds.width = width;
        }
                                               
        // Add the new text lines to the container.
        mx_internal::addTextLines(DisplayObjectContainer(drawnDisplayObject));

        // Figure out if a scroll rect is needed.
        mx_internal::isOverset = mx_internal::isTextOverset(width, height);
        
        // Just recomposed so reset.
        mx_internal::invalidateCompose = false;                
    }
    
    /**
     *  @private
     *  Cleans up and sets the validity of the lines disassociated with the 
     *  TextBlock to TextLineValidity.INVALID.
     */
    private function releaseLinesFromTextBlock(textLines:Array):void
    {
        var firstLine:TextLine = staticTextBlock.firstLine;
        var lastLine:TextLine = staticTextBlock.lastLine;
        
        if (firstLine)
            staticTextBlock.releaseLines(firstLine, lastLine);        
     }

    /**
     *  @private
     *  Returns true if the player being used supports recycling
     *  text lines.  Support was added in FP 10.1.
     */
    private function get recycleTextLines():Boolean
    {
        return "recreateTextLine" in staticTextBlock;
    }        
     
	/**
	 *  @private
	 *  Creates an ElementFormat (and its FontDescription)
	 *  based on the SimpleText's CSS styles.
	 *  These must be recreated each time because FTE
	 *  does not allow them to be reused.
	 */
	private function createElementFormat():ElementFormat
	{
		// When you databind to a text formatting style on a SimpleText,
		// as in <SimpleText fontFamily="{fontCombo.selectedItem}"/>
		// the databinding can cause the style to be set to null.
		// Setting null values for properties in an FTE FontDescription
		// or ElementFormat throw an error, so the following code does
		// null-checking on the problematic properties.
        
        var s:String;
        
        var fontDescription:FontDescription = new FontDescription();
        
        s = getStyle("cffHinting");
        if (s != null)
        	fontDescription.cffHinting = s;
        
        s = getStyle("fontLookup");
        if (s != null)
        	fontDescription.fontLookup = s;
        
        s = getStyle("fontFamily");
        if (s != null)
        	fontDescription.fontName = s;
        
        s = getStyle("fontStyle");
        if (s != null)
        	fontDescription.fontPosture = s;
        
        s = getStyle("fontWeight");
        if (s != null)
        	fontDescription.fontWeight = s;
        	
        s = getStyle("renderingMode");
        if (s != null)
        	fontDescription.renderingMode = s;
        
        var elementFormat:ElementFormat = new ElementFormat();
        
		s = getStyle("alignmentBaseline");
		if (s != null)
			elementFormat.alignmentBaseline = s;
			
        elementFormat.alpha = getStyle("textAlpha");
        	
        elementFormat.baselineShift = getStyle("baselineShift");
        	
        s = getStyle("breakOpportunity");
        if (s != null)
        	elementFormat.breakOpportunity = s;
        	
        elementFormat.color = getStyle("color");
        
        s = getStyle("digitCase");
        if (s != null)
        	elementFormat.digitCase = s;
        	
        s = getStyle("digitWidth");
        if (s != null)
        	elementFormat.digitWidth = s;
        	
        s = getStyle("dominantBaseline");
        if (s != null)
        	elementFormat.dominantBaseline = s;
        	
        elementFormat.fontDescription = fontDescription;
        
        elementFormat.fontSize = getStyle("fontSize");
        
        setKerning(elementFormat);
        
        s = getStyle("ligatureLevel");
        if (s != null)
        	elementFormat.ligatureLevel = s;
        
        s = getStyle("locale");
        if (s != null)
        	elementFormat.locale = s;
        
        setTracking(elementFormat);
        
        s = getStyle("typographicCase");
        if (s != null)
        	elementFormat.typographicCase = s;

		return elementFormat;
	}

    /**
     *  @private
     */
    private function setKerning(elementFormat:ElementFormat):void
    {
        var kerning:Object = getStyle("kerning");
        
        if (kerning === true)
            kerning = Kerning.ON;
        else if (kerning === false)
            kerning = Kerning.OFF;
        
        var s:String = String(kerning);
        if (s != null)
           elementFormat.kerning = s;
    }

    /**
     *  @private
     */
    private function setTracking(elementFormat:ElementFormat):void
    {
        var trackingLeft:Object = getStyle("trackingLeft");
        var trackingRight:Object = getStyle("trackingRight");
        
        if (trackingRight == null)
            trackingRight = getStyle("tracking");

        var value:Number;
        var fontSize:Number = elementFormat.fontSize;
       
        value = getNumberOrPercentOf(trackingLeft, fontSize);
        if (!isNaN(value))
            elementFormat.trackingLeft = value;

        value = getNumberOrPercentOf(trackingRight, fontSize);
        if (!isNaN(value))
            elementFormat.trackingRight = value;
    }

	/**
	 *  @private
	 *  Stuffs the specified text and formatting info into a TextBlock
     *  and uses it to create as many TextLines as fit into the bounds.
     *  Returns true if all the text was composed into textLines.
	 */
	private function createTextLines(elementFormat:ElementFormat):Boolean
	{
		// Get CSS styles that affect a TextBlock and its justifier.
		var direction:String = getStyle("direction");
        var justificationRule:String = getStyle("justificationRule");
        var justificationStyle:String = getStyle("justificationStyle");
        var textAlign:String = getStyle("textAlign");
        var textAlignLast:String = getStyle("textAlignLast");
        var textJustify:String = getStyle("textJustify");

		// Set the TextBlock's content.
        staticTextElement.text = text;
		staticTextElement.elementFormat = elementFormat;
		staticTextBlock.content = staticTextElement;

        // And its bidiLevel.
		staticTextBlock.bidiLevel = direction == "ltr" ? 0 : 1;

		// And its justifier.
		var lineJustification:String;
		if (textAlign == "justify")
		{
			lineJustification = textAlignLast == "justify" ?
				                LineJustification.ALL_INCLUDING_LAST :
				                LineJustification.ALL_BUT_LAST;
		}
		else
        {
			lineJustification = LineJustification.UNJUSTIFIED;
        }
		if (justificationRule == "space")
		{
            staticSpaceJustifier.lineJustification = lineJustification;
			staticSpaceJustifier.letterSpacing = textJustify == "distribute";
            staticTextBlock.textJustifier = staticSpaceJustifier;
		}
		else
		{
            staticEastAsianJustifier.lineJustification = lineJustification;
            staticEastAsianJustifier.justificationStyle = justificationStyle;
			
            staticTextBlock.textJustifier = staticEastAsianJustifier;
		}
                
		// Then create TextLines using this TextBlock.
		return createTextLinesFromTextBlock(staticTextBlock,
		                                    mx_internal::textLines,
		                                    mx_internal::bounds);
	}

	/**
	 *  @private
	 *  Compose into textLines.  bounds on input is size of composition
	 *  area and on output is the size of the composed content.
	 *  The caller must call releaseLinesFromTextBlock() to release the
	 *  textLines from the TextBlock.  This must be done after truncation
	 *  so that the composed lines can be broken into atoms to figure out
	 *  where the truncation indicator should be placed.
	 * 
     *  Returns true if all the text was composed into textLines.
	 */
	private function createTextLinesFromTextBlock(textBlock:TextBlock,
                	                              textLines:Array,
                	                              bounds:Rectangle):Boolean
	{
		// Get CSS styles for formats that we have to apply ourselves.
		var direction:String = getStyle("direction");
        var lineBreak:String = getStyle("lineBreak");
        var lineHeight:Object = getStyle("lineHeight");
        var lineThrough:Boolean = getStyle("lineThrough");
        var paddingBottom:Number = getStyle("paddingBottom");
        var paddingLeft:Number = getStyle("paddingLeft");
        var paddingRight:Number = getStyle("paddingRight");
        var paddingTop:Number = getStyle("paddingTop");
        var textAlign:String = getStyle("textAlign");
        var textAlignLast:String = getStyle("textAlignLast");
        var textDecoration:String = getStyle("textDecoration");
        var verticalAlign:String = getStyle("verticalAlign");

		var innerWidth:Number = bounds.width - paddingLeft - paddingRight;
		var innerHeight:Number = bounds.height - paddingTop - paddingBottom;
		
		if (isNaN(innerWidth))
			innerWidth = maxWidth;

        var maxLineWidth:Number = lineBreak == "explicit" ?
                                  TextLine.MAX_LINE_WIDTH :
                                  innerWidth;
		
		if (innerWidth < 0 || innerHeight < 0 || !textBlock)
		{
            textLines.length = 0;
			bounds.width = 0;
			bounds.height = 0;
			return false;
		}

		var fontSize:Number = staticTextElement.elementFormat.fontSize;
        var actualLineHeight:Number;
        if (lineHeight is Number)
        {
            actualLineHeight = Number(lineHeight);
        }
        else if (lineHeight is String)
        {
            var len:int = lineHeight.length;
            var percent:Number =
                Number(String(lineHeight).substring(0, len - 1));
            actualLineHeight = percent / 100 * fontSize;
        }
        if (isNaN(actualLineHeight))
            actualLineHeight = 1.2 * fontSize;
        
        var maxTextWidth:Number = 0;
		var totalTextHeight:Number = 0;
		
		var n:int = 0;
        var nRecycleLines:int = recycleTextLines ? textLines.length : 0;
		var nextTextLine:TextLine;
		var nextY:Number = 0;
		var textLine:TextLine;
        
		// For truncation, need to know if all lines have been composed.
		var createdAllLines:Boolean = false;
		
		// Generate TextLines, stopping when we run out of text
		// or reach the bottom of the requested bounds.
		// In this loop the lines are positioned within the rectangle
		// (0, 0, innerWidth, innerHeight), with top-left alignment.
		while (true)
		{
		    if (nRecycleLines > 0)
		    {
		        //trace("recreateTextLine", n);
		        var recycleLine:TextLine = textLines[n];
                nextTextLine = textBlock["recreateTextLine"]
                                    (recycleLine, textLine, maxLineWidth);		        
                nRecycleLines--;    
		    }
		    else
		    {
                nextTextLine = textBlock.createTextLine(textLine, maxLineWidth);
            }
            
			if (!nextTextLine)
            {
				createdAllLines = true;
                break;
            }
			
			// Determine the natural baseline position for this line.
			// Note: The y coordinate of a TextLine is the location
			// of its baseline, not of its top.
            nextY += (n == 0 ? nextTextLine.ascent : actualLineHeight);
			
			// If it is completely outside the rectangle, we're done.
			if (nextY - nextTextLine.ascent > innerHeight)
				break;

			// We'll keep this line. Put it into the textLines array.
			textLine = nextTextLine;
			textLines[n++] = textLine;
			
			// Assign its location based on left/top alignment.
			// Its x position is 0 by default.
			textLine.y = nextY;
			
			// Keep track of the maximum textWidth 
			// and the accumulated textHeight of the TextLines.
			maxTextWidth = Math.max(maxTextWidth, textLine.textWidth);
			totalTextHeight += textLine.textHeight;

            if (lineThrough || textDecoration == "underline")
            {
                // FTE doesn't render strikethroughs or underlines,
                // but it can tell us where to draw them.
                // You can't draw in a TextLine but it can have children,
                // so we create a child Shape to draw them in.
                
                var elementFormat:ElementFormat =
                    TextElement(textBlock.content).elementFormat;
                var fontMetrics:FontMetrics = elementFormat.getFontMetrics();
                
                var shape:Shape = new Shape();
                var g:Graphics = shape.graphics;
                if (lineThrough)
                {
                    g.lineStyle(fontMetrics.strikethroughThickness, 
                                elementFormat.color, elementFormat.alpha);
                    g.moveTo(0, fontMetrics.strikethroughOffset);
                    g.lineTo(textLine.textWidth, fontMetrics.strikethroughOffset);
                }
                if (textDecoration == "underline")
                {
                    g.lineStyle(fontMetrics.underlineThickness, 
                                elementFormat.color, elementFormat.alpha);
                    g.moveTo(0, fontMetrics.underlineOffset);
                    g.lineTo(textLine.textWidth, fontMetrics.underlineOffset);
                }
                
                textLine.addChild(shape);
            }
		}

        // If recycling text lines, eliminate any unused lines.
        textLines.length = n;
        
		// At this point, n is the number of lines that fit
		// and textLine is the last line that fit.

		if (n == 0)
		{
			bounds.width = paddingLeft + paddingRight;
			bounds.height = paddingTop + paddingBottom;
			return createdAllLines;
		}
		
        // innerWidth remains the same.  alignment is done over the innerWidth
        // not over the width of the text that was just composed.
		if (isNaN(bounds.height))
            innerHeight = textLine.y + textLine.descent;

        var leftAligned:Boolean = 
            textAlign == "start" && direction == "ltr" ||
            textAlign == "end" && direction == "rtl" ||
            textAlign == "left" ||
            textAlign == "justify";
        var centerAligned:Boolean = textAlign == "center";
        var rightAligned:Boolean =
            textAlign == "start" && direction == "rtl" ||
            textAlign == "end" && direction == "ltr" ||
            textAlign == "right"; 

		// Calculate loop constants for horizontal alignment.
		var leftOffset:Number = bounds.left + paddingLeft;
		var centerOffset:Number = leftOffset + innerWidth / 2;
		var rightOffset:Number =  leftOffset + innerWidth;
		
		// Calculate loop constants for vertical alignment.
		var topOffset:Number = bounds.top + paddingTop;
		var bottomOffset:Number = innerHeight - (textLine.y + textLine.descent);
		var middleOffset:Number = bottomOffset / 2;
		bottomOffset += topOffset;
		middleOffset += topOffset;
		var leading:Number = (innerHeight - totalTextHeight) / (n - 1);
		
		var previousTextLine:TextLine;
		var y:Number = 0;

        var lastLineIsSpecial:Boolean =
            textAlign == "justify" && createdAllLines;

        var minX:Number = innerWidth;
        var minY:Number = innerHeight;
        var maxX:Number = 0;
        
		// Reposition each line if necessary.
		// based on the horizontal and vertical alignment.
		for (var i:int = 0; i < n; i++)
		{
			textLine = TextLine(textLines[i]);

			// If textAlign is "justify" and there is more than one line,
            // the last one (if we created it) gets horizontal aligned
            // according to textAlignLast.
            if (lastLineIsSpecial && i == n - 1)
            {
                leftAligned = 
                    textAlignLast == "start" && direction == "ltr" ||
                    textAlignLast == "end" && direction == "rtl" ||
                    textAlignLast == "left" ||
                    textAlignLast == "justify";
                centerAligned = textAlignLast == "center";
                rightAligned =
                    textAlignLast == "start" && direction == "rtl" ||
                    textAlignLast == "end" && direction == "ltr" ||
                    textAlignLast == "right";
            } 

            if (leftAligned)
				textLine.x = leftOffset;
			else if (centerAligned)
				textLine.x = centerOffset - textLine.textWidth / 2;
			else if (rightAligned)
				textLine.x = rightOffset - textLine.textWidth;

			if (verticalAlign == "top")
			{
				textLine.y += topOffset;
			}
			else if (verticalAlign == "middle")
			{
				textLine.y += middleOffset;
			}
			else if (verticalAlign == "bottom")
			{
				textLine.y += bottomOffset;
			}
			else if (verticalAlign == "justify")
			{
				// Determine the natural baseline position for this line.
				// Note: The y coordinate of a TextLine is the location
				// of its baseline, not of its top.
				y += i == 0 ?
					 topOffset + textLine.ascent :
					 previousTextLine.descent + leading + textLine.ascent;
			
				textLine.y = y;
				previousTextLine = textLine;
			}

            // Upper left corner of bounding box may not be 0,0 after
            // styles are applied or rounding error from minY calculation.
            // y is one decimal place and ascent isn't rounded so minY can be 
            // slightly less than zero. 
            minX = Math.min(minX, textLine.x);             
            minY = Math.min(minY, textLine.y - textLine.ascent);
            maxX = Math.max(maxX, textLine.x + textLine.textWidth); 
		}

        bounds.x = minX - paddingLeft;
        bounds.y = minY - paddingTop;
        bounds.right = maxX + paddingRight;
        bounds.bottom = textLine.y + textLine.descent + paddingBottom;
        
        return createdAllLines;
	}
	
    /**
     *  @private
     *  width and height are the ones used to do the compose, not the measured
     *  results resulting from the compose.
     * 
     *  Adapted from justification code in TLF's
     *  TextLineFactory.textLinesFromString().
     */
	private function truncateText(width:Number, height:Number):void
	{
	    var lineCountLimit:int = truncation;
        var somethingFit:Boolean = false;
        var truncLineIndex:int = 0;    

        // Compute the truncation line.
        truncLineIndex = computeLastAllowedLineIndex(height, lineCountLimit);
                                     
        if (truncLineIndex >= 0)
        {
            // Estimate the initial truncation position using the following 
            // steps. 
            
            // 1. Measure the space that the truncation indicator will take
            // by composing the truncation resource using the same bounds
            // and formats.
            staticTextElement.text = mx_internal::truncationIndicatorResource;
            var measureLines:Array = new Array();
            var measureBounds:Rectangle = new Rectangle(0, 0, width, NaN);
    
            createTextLinesFromTextBlock(staticTextBlock, 
                                         measureLines, 
                                         measureBounds);
                                               
            releaseLinesFromTextBlock(measureLines);
                                                                                  
            // 2. Move target line for truncation higher by as many lines 
            // as the number of full lines taken by the truncation 
            // indicator.
            truncLineIndex -= (measureLines.length - 1);
            if (truncLineIndex >= 0)
            {
                // 3. Calculate allowed width (width left over from the 
                // last line of the truncation indicator).
                var measuredTextLine:TextLine = 
                        TextLine(measureLines[measureLines.length-1]);      
                var allowedWidth:Number = 
                    measuredTextLine.specifiedWidth -
                    measuredTextLine.unjustifiedTextWidth;                          
                                        
                // 4. Get the initial truncation position on the target 
                // line given this allowed width. 
                var truncateAtCharPosition:int = 
                    getTruncationPosition(mx_internal::textLines[truncLineIndex], 
                                          allowedWidth);

                // The following loop executes repeatedly composing text until 
                // it fits.  In each iteration, an atoms's worth of characters 
                // of original content is dropped
                do
                {
                    // Replace all content starting at the inital truncation 
                    // position with the truncation indicator.
                    var truncText:String = 
                            text.slice(0, truncateAtCharPosition) +
                                       mx_internal::truncationIndicatorResource;

                    // (Re)-initialize bounds for next compose.
                    mx_internal::bounds.x = 0;
                    mx_internal::bounds.y = 0;
                    mx_internal::bounds.width = width;
                    mx_internal::bounds.height = height;
                                                                                    
                    staticTextElement.text = truncText;
                    var createdAllLines:Boolean = 
                        createTextLinesFromTextBlock(staticTextBlock,
                                                     mx_internal::textLines,
                                                     mx_internal::bounds);
        
                    if (doesComposedTextFit(height, 
                                            createdAllLines, 
                                            lineCountLimit))
                    {
                        somethingFit = true;
                        break; 
                    }       
                    
                     // No original content left to make room for 
                     // truncation indicator.
                    if (truncateAtCharPosition == 0)
                        break;
                    
                    // Try again by truncating at the beginning of the 
                    // preceding atom.
                    truncateAtCharPosition = 
                            getNextTruncationPosition(truncLineIndex,
                                                      truncateAtCharPosition);                            
                } while (true);
            }
        }
        
        // If nothing fit, return no lines and bounds that just contains
        // padding.
        if (!somethingFit)
        {
            mx_internal::textLines.length = 0;

            var paddingBottom:Number = getStyle("paddingBottom");
            var paddingLeft:Number = getStyle("paddingLeft");
            var paddingRight:Number = getStyle("paddingRight");
            var paddingTop:Number = getStyle("paddingTop");
            
            mx_internal::bounds.x = 0;
            mx_internal::bounds.y = 0;
            mx_internal::bounds.width = paddingLeft + paddingRight;
            mx_internal::bounds.height = paddingTop + paddingBottom;
        }
    }
        
    /**
     * Determines if the composed text fits in the given height and 
     * line count limit. 
     */ 
    private function doesComposedTextFit(height:Number,
                                         createdAllLines:Boolean,
                                         lineCountLimit:int):Boolean
    {
        var textLines:Array = mx_internal::textLines;

        // Not all text composed because it didn't fit within bounds.
        if (!createdAllLines)
            return false;
                    
        // More text lines than allowed lines.                    
        if (lineCountLimit != -1 && textLines.length > lineCountLimit)
            return false;
        
        // No lines or no height restriction.
        if (!textLines.length || isNaN(height))
            return true;
                                             
        // Does the bottom of the last line fall within the bounds?                                                    
        var lastLine:TextLine = TextLine(textLines[textLines.length - 1]);        
        var lastLineExtent:Number = lastLine.y + lastLine.descent;
        
        return lastLineExtent <= height;
    }

    /** 
     * Calculates the last line that fits in the given height and line count 
     * limit.
     */
    private function computeLastAllowedLineIndex(height:Number,
                                                 lineCountLimit:int):int
    {           
        var textLines:Array = mx_internal::textLines;
        var truncationLineIndex:int = textLines.length - 1;
        
        if (!isNaN(height))
        {
            // Search in reverse order since truncation near the end is the 
            // more common use case.
            do
            {
                var textLine:TextLine = TextLine(textLines[truncationLineIndex]);
                if (textLine.y + textLine.descent <= height)
                    break;
                                
                truncationLineIndex--;
            }
            while (truncationLineIndex >= 0);
        }   
    
        // if line count limit is smaller, use that
        if (lineCountLimit != -1 && lineCountLimit <= truncationLineIndex)
            truncationLineIndex = lineCountLimit - 1;            
            
        return truncationLineIndex;            
    }

    /** 
     * Gets the truncation position on a line given the allowed width.
     * - Must be at an atom boundary.
     * - Must scan the line for atoms in logical order, not physical position 
     *   order.
     * For example, given bi-di text ABאבCD
     * atoms must be scanned in this order: 
     * A, B, א
     * ג, C, D  
     */
    private function getTruncationPosition(line:TextLine, 
                                           allowedWidth:Number):int
    {           
        var consumedWidth:Number = 0;
        var charPosition:int = line.textBlockBeginIndex;
        
        while (charPosition < line.textBlockBeginIndex + line.rawTextLength)
        {
            var atomIndex:int = line.getAtomIndexAtCharIndex(charPosition);
            var atomBounds:Rectangle = line.getAtomBounds(atomIndex); 
            consumedWidth += atomBounds.width;
            if (consumedWidth > allowedWidth)
                break;
                
            charPosition = line.getAtomTextBlockEndIndex(atomIndex);
        }
        
        line.flushAtomData();
        
        return charPosition;
    }
        
    /** 
     * Gets the next truncation position by shedding an atom's worth of 
     * characters.
     */
    private function getNextTruncationPosition(truncationLineIndex:int,
                                               truncateAtCharPosition:int):int
    {
        var textLines:Array = mx_internal::textLines;

        // 1. Get the position of the last character of the preceding atom
        // truncateAtCharPosition-1, because truncateAtCharPosition is an 
        // atom boundary.
        truncateAtCharPosition--; 
        
        // 2. Find the new target line (i.e., the line that has the new 
        // truncation position).  If the last truncation position was at the 
        // beginning of the target line, the new position may have moved to a 
        // previous line.  It is also possible for this position to be found 
        // in the next line because the truncation indicator may have combined 
        // with original content to form a word that may not have afforded a 
        // suitable break opportunity.  In any case, the new truncation 
        // position lies in the vicinity of the previous target line, so a 
        // linear search suffices.
        var line:TextLine = TextLine(textLines[truncationLineIndex]);
        do
        {
            if (truncateAtCharPosition >= line.textBlockBeginIndex && 
                truncateAtCharPosition < line.textBlockBeginIndex + line.rawTextLength)
            {
                break;
            }
            if (truncateAtCharPosition < line.textBlockBeginIndex)
                truncationLineIndex--;
            else
                truncationLineIndex++;
            line = TextLine(textLines[truncationLineIndex]);
        }
        while (true);

        // 3. Get the line atom index at this position          
        var atomIndex:int = 
                        line.getAtomIndexAtCharIndex(truncateAtCharPosition);
        
        // 4. Get the char index for this atom index
        var nextTruncationPosition:int = 
                        line.getAtomTextBlockBeginIndex(atomIndex);
        
        line.flushAtomData();
        
        return nextTruncationPosition;
    } 
        
}

}
