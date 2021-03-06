#import "TGSharedMediaLinkItem.h"

#import <LegacyComponents/LegacyComponents.h>

#import "TGSharedMediaDirectionFilter.h"

#import "TGModernTextViewModel.h"
#import "TGReusableLabel.h"

#import "TGSharedPhotoSignals.h"
#import "TGSharedMediaUtils.h"
#import "TGSharedMediaSignals.h"

#import "TGPresentation.h"

@interface TGSharedMediaLinkItem ()
{
    int32_t _messageId;
    NSTimeInterval _date;
    bool _incoming;
    
    TGModernTextViewModel *_textModel;
    TGWebPageMediaAttachment *_webPage;
    NSArray *_links;
    
    TGPresentation *_presentation;
}

@end

@implementation TGSharedMediaLinkItem

- (instancetype)initWithMessage:(TGMessage *)message messageId:(int32_t)messageId date:(NSTimeInterval)date incoming:(bool)incoming presentation:(TGPresentation *)presentation
{
    self = [super init];
    if (self != nil)
    {
        _message = message;
        _messageId = messageId;
        _date = date;
        _incoming = incoming;
        _presentation = presentation;
    
        for (id attachment in message.mediaAttachments)
        {
            if ([attachment isKindOfClass:[TGWebPageMediaAttachment class]])
            {
                _webPage = attachment;
                break;
            }
        }
        
        NSMutableArray *links = [[NSMutableArray alloc] init];
        NSString *title = nil;
        for (id result in [TGMessage textCheckingResultsForText:message.text highlightMentionsAndTags:false highlightCommands:false entities:nil])
        {
            if ([result isKindOfClass:[NSTextCheckingResult class]])
            {
                NSURL *url = ((NSTextCheckingResult *)result).URL;
                if (url != nil)
                {
                    if (title == nil)
                    {
                        NSString *host = url.host;
                        NSRange dotRange = [host rangeOfString:@"." options:NSBackwardsSearch];
                        if (dotRange.location != NSNotFound)
                            host = [host substringToIndex:dotRange.location];
                        
                        if (host.length == 1)
                            title = [host capitalizedString];
                        else if (host.length != 0)
                        {
                            title = [[[host substringToIndex:1] capitalizedString] stringByAppendingString:[host substringFromIndex:1]];
                        }
                    }
                    [links addObject:[url absoluteString]];
                }
            }
        }
        _links = links;
        
        NSMutableString *linksText = [[NSMutableString alloc] init];
        for (NSString *link in links)
        {
            if (linksText.length != 0)
                [linksText appendString:@"\n"];
            [linksText appendString:link];
        }

        NSString *rawText = message.text;
        if ([rawText isEqual:linksText])
        {
            if (_webPage != nil && _webPage.pageDescription.length != 0)
                rawText = _webPage.pageDescription;
            else
                rawText = @"";
        }
        if (rawText == nil)
            rawText = @"";
        NSMutableString *text = [[NSMutableString alloc] initWithString:rawText];
        [text replaceOccurrencesOfString:@"\n\n" withString:@"\n" options:0 range:NSMakeRange(0, text.length)];
        [text replaceOccurrencesOfString:@"\t" withString:@"" options:0 range:NSMakeRange(0, text.length)];
        _textModel = [[TGModernTextViewModel alloc] initWithText:text font:TGCoreTextSystemFontOfSize(13.0f)];
        _textModel.additionalLineSpacing = 2.0f;
        _textModel.layoutFlags = TGReusableLabelLayoutMultiline;
        _textModel.maxNumberOfLines = 2;
        _textModel.textColor = presentation.pallete.secondaryTextColor;
    }
    return self;
}

- (TGModernTextViewModel *)textModel
{
    return _textModel;
}

- (SSignal *)imageSignal
{
    if (_webPage.photo != nil)
    {
        NSString *key = [[NSString alloc] initWithFormat:@"webpage-image-%" PRId64 "", _webPage.photo.imageId];
        return [TGSharedPhotoSignals sharedPhotoImage:_webPage.photo size:CGSizeMake(80.0f, 80.0f) threadPool:[TGSharedMediaUtils sharedMediaImageProcessingThreadPool] memoryCache:[TGSharedMediaUtils sharedMediaMemoryImageCache] pixelProcessingBlock:[TGSharedMediaSignals pixelProcessingBlockForRoundCornersOfRadius:10.0f] cacheKey:key];
    }
    else
        return nil;
}

- (TGWebPageMediaAttachment *)webPage
{
    return _webPage;
}

- (NSArray *)links
{
    return _links;
}

- (CGFloat)heightForWidth:(CGFloat)width
{
    if (_textModel.text.length == 0 || [_textModel.text isEqualToString:@" "])
    {
        _textModel.frame = CGRectMake(0.0f, 0.0f, 0.0f, 0.0f);
        return MAX(_textModel.frame.size.height + 35.0f + _links.count * 20.0f, 61.0f);
    }
    else
    {
        [_textModel layoutForContainerSize:CGSizeMake(width - 91.0f, CGFLOAT_MAX)];
        return _textModel.frame.size.height + 38.0f + _links.count * 20.0f;
    }
}

- (instancetype)copyWithZone:(NSZone *)__unused zone
{
    return [[TGSharedMediaLinkItem alloc] initWithMessage:_message messageId:_messageId date:_date incoming:_incoming presentation:_presentation];
}

- (BOOL)isEqual:(id)object
{
    return [object isKindOfClass:[TGSharedMediaLinkItem class]] && ((TGSharedMediaLinkItem *)object)->_messageId == _messageId;
}

- (NSUInteger)hash
{
    return _messageId;
}

- (int32_t)messageId
{
    return _messageId;
}

- (NSTimeInterval)date
{
    return _date;
}

- (bool)passesFilter:(id<TGSharedMediaFilter>)filter
{
    if ([filter isKindOfClass:[TGSharedMediaDirectionFilter class]])
    {
        switch (((TGSharedMediaDirectionFilter *)filter).direction)
        {
            case TGSharedMediaDirectionBoth:
                return true;
            case TGSharedMediaDirectionIncoming:
                return _incoming;
            case TGSharedMediaDirectionOutgoing:
                return !_incoming;
        }
    }
    return false;
}

@end
