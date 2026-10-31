import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:archive/archive.dart';

/// Service for exporting summaries as TXT and DOCX files.
class FileExportService {
  /// Exports the given [bullets] as a plain-text file and shares it.
  Future<void> exportAsTxt(List<String> bullets) async {
    final buffer = StringBuffer();
    buffer.writeln('SummarizIt — Summary');
    buffer.writeln('=' * 40);
    buffer.writeln();
    for (int i = 0; i < bullets.length; i++) {
      buffer.writeln('• ${bullets[i]}');
      buffer.writeln();
    }

    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/summary.txt');
    await file.writeAsString(buffer.toString());

    await Share.shareXFiles(
      [XFile(file.path)],
      subject: 'SummarizIt Summary',
    );
  }

  /// Generates the in-memory Open XML ZIP [Archive] for the DOCX document.
  Archive buildDocxArchive(List<String> bullets) {
    // Build bullet paragraphs XML
    final paragraphs = StringBuffer();
    // Title paragraph
    paragraphs.write('''
<w:p>
  <w:pPr><w:jc w:val="center"/></w:pPr>
  <w:r>
    <w:rPr><w:b/><w:sz w:val="36"/><w:color w:val="6C63FF"/></w:rPr>
    <w:t>SummarizIt — Summary</w:t>
  </w:r>
</w:p>
<w:p/>
''');
    // Bullet paragraphs
    for (final bullet in bullets) {
      final escaped = _escapeXml(bullet);
      paragraphs.write('''
<w:p>
  <w:pPr>
    <w:numPr><w:ilvl w:val="0"/><w:numId w:val="1"/></w:numPr>
  </w:pPr>
  <w:r>
    <w:rPr><w:sz w:val="22"/></w:rPr>
    <w:t xml:space="preserve">$escaped</w:t>
  </w:r>
</w:p>
''');
    }

    final documentXml = '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<w:document xmlns:wpc="http://schemas.microsoft.com/office/word/2010/wordprocessingCanvas"
            xmlns:mo="http://schemas.microsoft.com/office/mac/office/2008/main"
            xmlns:mc="http://schemas.openxmlformats.org/markup-compatibility/2006"
            xmlns:mv="urn:schemas-microsoft-com:mac:vml"
            xmlns:o="urn:schemas-microsoft-com:office:office"
            xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships"
            xmlns:m="http://schemas.openxmlformats.org/officeDocument/2006/math"
            xmlns:v="urn:schemas-microsoft-com:vml"
            xmlns:wp="http://schemas.openxmlformats.org/drawingml/2006/wordprocessingDrawing"
            xmlns:w10="urn:schemas-microsoft-com:office:word"
            xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main"
            xmlns:wne="http://schemas.microsoft.com/office/word/2006/wordml">
  <w:body>
    ${paragraphs.toString()}
  </w:body>
</w:document>''';

    final contentTypesXml = '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">
  <Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>
  <Default Extension="xml" ContentType="application/xml"/>
  <Override PartName="/word/document.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.document.main+xml"/>
  <Override PartName="/word/numbering.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.numbering+xml"/>
</Types>''';

    final relsXml = '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
  <Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="word/document.xml"/>
</Relationships>''';

    final wordRelsXml = '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
  <Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/numbering" Target="numbering.xml"/>
</Relationships>''';

    final numberingXml = '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<w:numbering xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main">
  <w:abstractNum w:abstractNumId="0">
    <w:lvl w:ilvl="0">
      <w:start w:val="1"/>
      <w:numFmt w:val="bullet"/>
      <w:lvlText w:val="•"/>
      <w:lvlJc w:val="left"/>
    </w:lvl>
  </w:abstractNum>
  <w:num w:numId="1">
    <w:abstractNumId w:val="0"/>
  </w:num>
</w:numbering>''';

    final archive = Archive();
    archive.addFile(
      ArchiveFile.bytes('[Content_Types].xml', Uint8List.fromList(utf8.encode(contentTypesXml))),
    );
    archive.addFile(
      ArchiveFile.bytes('_rels/.rels', Uint8List.fromList(utf8.encode(relsXml))),
    );
    archive.addFile(
      ArchiveFile.bytes('word/document.xml', Uint8List.fromList(utf8.encode(documentXml))),
    );
    archive.addFile(
      ArchiveFile.bytes('word/_rels/document.xml.rels', Uint8List.fromList(utf8.encode(wordRelsXml))),
    );
    archive.addFile(
      ArchiveFile.bytes('word/numbering.xml', Uint8List.fromList(utf8.encode(numberingXml))),
    );

    return archive;
  }

  /// Encodes the DOCX document for [bullets] into a ZIP byte array.
  List<int> generateDocxBytes(List<String> bullets) {
    final archive = buildDocxArchive(bullets);
    return ZipEncoder().encode(archive);
  }

  /// Exports the given [bullets] as a DOCX file and shares it.
  Future<void> exportAsDocx(List<String> bullets) async {
    final zipData = generateDocxBytes(bullets);

    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/summary.docx');
    await file.writeAsBytes(zipData);

    await Share.shareXFiles(
      [XFile(file.path)],
      subject: 'SummarizIt Summary',
    );
  }

  String _escapeXml(String input) {
    return input
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&apos;');
  }
}
