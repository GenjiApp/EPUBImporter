#include <CoreFoundation/CoreFoundation.h>
#include <CoreServices/CoreServices.h>
#import "Cocoa/Cocoa.h"
#import "GNJUnZip.h"

/* -----------------------------------------------------------------------------
   Step 1
   Set the UTI types the importer supports
  
   Modify the CFBundleDocumentTypes entry in Info.plist to contain
   an array of Uniform Type Identifiers (UTI) for the LSItemContentTypes 
   that your importer can handle
  
   ----------------------------------------------------------------------------- */

/* -----------------------------------------------------------------------------
   Step 2 
   Implement the GetMetadataForURL function
  
   Implement the GetMetadataForURL function below to scrape the relevant
   metadata from your document and return it as a CFDictionary using standard keys
   (defined in MDItem.h) whenever possible.
   ----------------------------------------------------------------------------- */

/* -----------------------------------------------------------------------------
   Step 3 (optional) 
   If you have defined new attributes, update schema.xml and schema.strings files
   
   The schema.xml should be added whenever you need attributes displayed in 
   Finder's get info panel, or when you have custom attributes.  
   The schema.strings should be added whenever you have custom attributes. 
 
   Edit the schema.xml file to include the metadata keys that your importer returns.
   Add them to the <allattrs> and <displayattrs> elements.
  
   Add any custom types that your importer requires to the <attributes> element
  
   <attribute name="com_mycompany_metadatakey" type="CFString" multivalued="true"/>
  
   ----------------------------------------------------------------------------- */



/* -----------------------------------------------------------------------------
    Get metadata attributes from file
   
   This function's job is to extract useful information your file format supports
   and return it as a dictionary
   ----------------------------------------------------------------------------- */

Boolean GetMetadataForURL(void* thisInterface, 
                          CFMutableDictionaryRef attributes, 
                          CFStringRef contentTypeUTI,
                          CFURLRef urlForFile)
{
  /* Pull any available metadata from the file at the specified path */
  /* Return the attribute keys and attribute values in the dict */
  /* Return TRUE if successful, FALSE if there was no data provided */

  NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];

  NSString *path = [(NSURL *)urlForFile path];
  GNJUnZip *unzip = [[GNJUnZip alloc] initWithZipFile:path];

  NSData *xmlData = [unzip dataWithContentsOfFile:@"META-INF/container.xml"];
  if(!xmlData) {
    [unzip release];
    [pool release];
    return FALSE;
  }
  NSXMLDocument *xmlDoc = [[NSXMLDocument alloc] initWithData:xmlData
                                                      options:NSXMLDocumentTidyXML
                                                        error:NULL];
  if(!xmlDoc) {
    [unzip release];
    [pool release];
    return FALSE;
  }
  NSString *xpath = @"/container/rootfiles/rootfile/@full-path";
  NSArray *nodes = [xmlDoc nodesForXPath:xpath error:NULL];
  if(![nodes count]) {
    [xmlDoc release];
    [unzip release];
    [pool release];
    return FALSE;
  }
  NSString *opfPath = [[nodes objectAtIndex:0] stringValue];
  [xmlDoc release];

  xmlData = [unzip dataWithContentsOfFile:opfPath];
  if(!xmlDoc) {
    [unzip release];
    [pool release];
    return FALSE;
  }
  xmlDoc = [[NSXMLDocument alloc] initWithData:xmlData
                                       options:NSXMLDocumentTidyXML
                                         error:NULL];
  if(!xmlDoc) {
    [xmlDoc release];
    [unzip release];
    [pool release];
    return FALSE;
  }
  xpath = @"/package/metadata/*";
  nodes = [xmlDoc nodesForXPath:xpath error:NULL];
  if(![nodes count]) {
    [xmlDoc release];
    [unzip release];
    [pool release];
    return FALSE;
  }

  NSMutableArray *titles = [NSMutableArray array];
  NSMutableArray *authors = [NSMutableArray array];
  NSMutableArray *subjects = [NSMutableArray array];
  NSString *description = nil;
  NSMutableArray *publishers = [NSMutableArray array];
  NSMutableArray *contributors = [NSMutableArray array];
  NSMutableArray *identifiers = [NSMutableArray array];
  NSMutableArray *languages = [NSMutableArray array];
  NSString *coverage = nil;
  NSString *copyright = nil;

  for(NSXMLNode *node in nodes) {
    NSString *nodeName = [node name];
    if([nodeName isEqualToString:@"dc:title"]) {
      [titles addObject:[node stringValue]];
    }
    else if([nodeName isEqualToString:@"dc:creator"]) {
      [authors addObject:[node stringValue]];
    }
    else if([nodeName isEqualToString:@"dc:subject"]) {
      [subjects addObject:[node stringValue]];
    }
    else if([nodeName isEqualToString:@"dc:description"]) {
      description = [NSString stringWithString:[node stringValue]];
    }
    else if([nodeName isEqualToString:@"dc:publisher"]) {
      [publishers addObject:[node stringValue]];
    }
    else if([nodeName isEqualToString:@"dc:contributor"]) {
      [contributors addObject:[node stringValue]];
    }
    else if([nodeName isEqualToString:@"dc:identifier"]) {
      [identifiers addObject:[node stringValue]];
    }
    else if([nodeName isEqualToString:@"dc:language"]) {
      [languages addObject:[node stringValue]];
    }
    else if([nodeName isEqualToString:@"dc:coverage"]) {
      coverage = [NSString stringWithString:[node stringValue]];
    }
    else if([nodeName isEqualToString:@"dc:rights"]) {
      copyright = [NSString stringWithString:[node stringValue]];
    }
  }

  NSMutableArray *bodies = [NSMutableArray array];
  xpath = @"/package/manifest/item";
  nodes = [xmlDoc nodesForXPath:xpath error:NULL];
  if(![nodes count]) {
    [xmlDoc release];
    [unzip release];
    [pool release];
    return FALSE;
  }
  NSMutableDictionary *manifest = [NSMutableDictionary dictionary];
  for(NSXMLElement *elem in nodes) {
    NSXMLNode *idNode = [elem attributeForName:@"id"];
    NSXMLNode *hrefNode = [elem attributeForName:@"href"];
    [manifest setObject:[hrefNode stringValue] forKey:[idNode stringValue]];
  }
  xpath = @"/package/spine/itemref/@idref";
  nodes = [xmlDoc nodesForXPath:xpath error:NULL];
  if(![nodes count]) {
    [xmlDoc release];
    [unzip release];
    [pool release];
    return FALSE;
  }
  for(NSXMLNode *node in nodes) {
    NSString *key = [node stringValue];
    NSString *opfBasePath = [opfPath stringByDeletingLastPathComponent];
    NSString *path = [opfBasePath
                      stringByAppendingPathComponent:[manifest objectForKey:key]];
    NSData *htmlData = [unzip dataWithContentsOfFile:path];
    if(htmlData) {
      NSXMLDocument *htmlDoc;
      htmlDoc = [[NSXMLDocument alloc] initWithData:htmlData
                                            options:NSXMLDocumentTidyHTML
                                              error:NULL];
      if(htmlDoc) {
        NSArray *nodes = [htmlDoc nodesForXPath:@"/html" error:NULL];
        if([nodes count]) {
          NSXMLNode *bodyNode = [nodes objectAtIndex:0];
          NSString *bodyString = [bodyNode stringValue];
          [bodies addObject:bodyString];
        }
      }
      [htmlDoc release];
    }
  }
  [xmlDoc release];
  [unzip release];

  if([titles count]) {
    NSString *titleString = [titles componentsJoinedByString:@", "];
    [(NSMutableDictionary *)attributes setObject:titleString
                                         forKey:(NSString *)kMDItemTitle];
  }
  if([authors count]) {
    [(NSMutableDictionary *)attributes setObject:authors
                                          forKey:(NSString *)kMDItemAuthors];
  }
  if([subjects count]) {
    [(NSMutableDictionary *)attributes setObject:subjects
                                          forKey:(NSString *)kMDItemKeywords];
  }
  if([description length]) {
    [(NSMutableDictionary *)attributes setObject:description
                                          forKey:(NSString *)kMDItemDescription];
    [(NSMutableDictionary *)attributes setObject:description
                                          forKey:(NSString *)kMDItemHeadline];
  }
  if([publishers count]) {
    [(NSMutableDictionary *)attributes setObject:publishers
                                          forKey:(NSString *)kMDItemPublishers];
    [(NSMutableDictionary *)attributes setObject:publishers
                                          forKey:(NSString *)kMDItemOrganizations];
  }
  if([contributors count]) {
    [(NSMutableDictionary *)attributes setObject:contributors
                                          forKey:(NSString *)kMDItemContributors];
  }
  if([identifiers count]) {
    NSString *idString = [identifiers componentsJoinedByString:@", "];
    [(NSMutableDictionary *)attributes setObject:idString
                                         forKey:(NSString *)kMDItemIdentifier];
  }
  if([languages count]) {
    [(NSMutableDictionary *)attributes setObject:languages
                                          forKey:(NSString *)kMDItemLanguages];
  }
  if([coverage length]) {
    [(NSMutableDictionary *)attributes setObject:coverage
                                          forKey:(NSString *)kMDItemCoverage];
  }
  if([copyright length]) {
    [(NSMutableDictionary *)attributes setObject:copyright
                                          forKey:(NSString *)kMDItemCopyright];
    [(NSMutableDictionary *)attributes setObject:copyright
                                          forKey:(NSString *)kMDItemRights];
  }
  if([bodies count]) {
    NSString *bodyString = [bodies componentsJoinedByString:@" "];
    [(NSMutableDictionary *)attributes setObject:bodyString
                                          forKey:(NSString *)kMDItemTextContent];

    NSNumber *numberOfPages = [NSNumber numberWithInteger:[bodies count]];
    [(NSMutableDictionary *)attributes setObject:numberOfPages
                                          forKey:(NSString *)kMDItemNumberOfPages];
  }

  [pool release];

  return TRUE;
}
