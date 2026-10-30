#!/usr/bin/env python3
"""Build OData V4 $metadata for the two security services from the CDS sources.

The SAP system is not required. Entity sets come from the service definitions.
Property names and EDM types come from the custom entities. Gateway names each
entity type with the entity set name plus the suffix Type.
"""

from pathlib import Path
import re
import xml.etree.ElementTree as ET

ROOT = Path(__file__).resolve().parents[1]
SRC = ROOT / "src"
OUT = Path(__file__).resolve().parent

SERVICES = ("zapi_sec_settings", "zapi_sec_access")

EDMX = "http://docs.oasis-open.org/odata/ns/edmx"
EDM = "http://docs.oasis-open.org/odata/ns/edm"


def esc(value):
    return (
        value.replace("&", "&amp;")
        .replace("<", "&lt;")
        .replace(">", "&gt;")
        .replace('"', "&quot;")
    )


def parse_service(name):
    text = (SRC / f"{name}.srvd.srvdsrv").read_text()
    label = re.search(r"@EndUserText\.label:\s*'([^']*)'", text).group(1)
    exposes = re.findall(r"expose\s+(\w+)\s+as\s+(\w+)\s*;", text)
    return label, exposes


def parse_entity(cds_name):
    text = (SRC / f"{cds_name.lower()}.ddls.asddls").read_text()
    label = re.search(r"@EndUserText\.label:\s*'([^']*)'", text).group(1)
    body = text.split("{", 1)[1].rsplit("}", 1)[0]
    properties = []
    for raw in body.split(";"):
        line = " ".join(raw.split())
        if not line:
            continue
        key = line.startswith("key ")
        if key:
            line = line[4:]
        name, type_name = [part.strip() for part in line.split(":", 1)]
        properties.append((name, type_name, key))
    return label, properties


def edm_type(type_name):
    if type_name == "abap.clnt":
        return 'Type="Edm.String" MaxLength="3"', None
    match = re.fullmatch(r"abap\.char\((\d+)\)", type_name)
    if match:
        return f'Type="Edm.String" MaxLength="{match.group(1)}"', None
    match = re.fullmatch(r"abap\.numc\((\d+)\)", type_name)
    if match:
        return f'Type="Edm.String" MaxLength="{match.group(1)}"', "digit"
    match = re.fullmatch(r"abap\.string\(\d+\)", type_name)
    if match:
        return 'Type="Edm.String"', None
    if type_name == "abap.dats":
        return 'Type="Edm.Date"', None
    if type_name == "abap.tims":
        return 'Type="Edm.TimeOfDay"', None
    if type_name == "abap.int2":
        return 'Type="Edm.Int16"', None
    if type_name == "abap.int4":
        return 'Type="Edm.Int32"', None
    match = re.fullmatch(r"abap\.dec\((\d+),(\d+)\)", type_name)
    if match:
        return f'Type="Edm.Decimal" Precision="{match.group(1)}" Scale="{match.group(2)}"', None
    raise SystemExit(f"unmapped CDS type {type_name}")


def render(service_name):
    label, exposes = parse_service(service_name)
    namespace = f"com.sap.gateway.srvd.{service_name}.v0001"
    entities = []
    for cds_name, alias in exposes:
        entity_label, properties = parse_entity(cds_name)
        entities.append((alias, entity_label, properties))

    lines = [
        '<?xml version="1.0" encoding="utf-8"?>',
        "<!--",
        f"  OData V4 $metadata for {service_name.upper()} version 0001.",
        "  Produced from the service definition and custom entities in src/.",
        "  Regenerate with: python3 metadata/build.py",
        "-->",
        f'<edmx:Edmx Version="4.0" xmlns:edmx="{EDMX}" xmlns="{EDM}">',
        '  <edmx:Reference Uri="https://sap.github.io/odata-vocabularies/vocabularies/Common.xml">',
        '    <edmx:Include Namespace="com.sap.vocabularies.Common.v1" Alias="SAP__common"/>',
        "  </edmx:Reference>",
        '  <edmx:Reference Uri="https://oasis-tcs.github.io/odata-vocabularies/vocabularies/Org.OData.Core.V1.xml">',
        '    <edmx:Include Namespace="Org.OData.Core.V1" Alias="SAP__core"/>',
        "  </edmx:Reference>",
        '  <edmx:Reference Uri="https://oasis-tcs.github.io/odata-vocabularies/vocabularies/Org.OData.Capabilities.V1.xml">',
        '    <edmx:Include Namespace="Org.OData.Capabilities.V1" Alias="SAP__capabilities"/>',
        "  </edmx:Reference>",
        "  <edmx:DataServices>",
        f'    <Schema Namespace="{namespace}" Alias="SAP__self">',
        '      <Annotation Term="SAP__core.SchemaVersion" String="1.0.0"/>',
        f'      <EntityContainer Name="Container">',
    ]
    for alias, _entity_label, _properties in entities:
        lines.append(
            f'        <EntitySet Name="{alias}" EntityType="{namespace}.{alias}Type"/>'
        )
    lines.append("      </EntityContainer>")

    digit_targets = []
    for alias, entity_label, properties in entities:
        lines.append(f'      <EntityType Name="{alias}Type">')
        lines.append("        <Key>")
        for name, _type_name, key in properties:
            if key:
                lines.append(f'          <PropertyRef Name="{name}"/>')
        lines.append("        </Key>")
        for name, type_name, key in properties:
            edm, kind = edm_type(type_name)
            nullable = ' Nullable="false"' if key else ""
            lines.append(f'        <Property Name="{name}" {edm}{nullable}/>')
            if kind == "digit":
                digit_targets.append(f"{alias}Type/{name}")
        lines.append("      </EntityType>")

    lines.append('      <Annotations Target="SAP__self.Container">')
    lines.append(f'        <Annotation Term="SAP__common.Label" String="{esc(label)}"/>')
    lines.append("      </Annotations>")

    for alias, entity_label, _properties in entities:
        lines.append(f'      <Annotations Target="SAP__self.{alias}Type">')
        lines.append(
            f'        <Annotation Term="SAP__common.Label" String="{esc(entity_label)}"/>'
        )
        lines.append("      </Annotations>")
        lines.append(f'      <Annotations Target="SAP__self.Container/{alias}">')
        lines.extend(
            [
                '        <Annotation Term="SAP__capabilities.ReadRestrictions">',
                "          <Record>",
                '            <PropertyValue Property="Readable" Bool="true"/>',
                "          </Record>",
                "        </Annotation>",
                '        <Annotation Term="SAP__capabilities.InsertRestrictions">',
                "          <Record>",
                '            <PropertyValue Property="Insertable" Bool="false"/>',
                "          </Record>",
                "        </Annotation>",
                '        <Annotation Term="SAP__capabilities.UpdateRestrictions">',
                "          <Record>",
                '            <PropertyValue Property="Updatable" Bool="false"/>',
                "          </Record>",
                "        </Annotation>",
                '        <Annotation Term="SAP__capabilities.DeleteRestrictions">',
                "          <Record>",
                '            <PropertyValue Property="Deletable" Bool="false"/>',
                "          </Record>",
                "        </Annotation>",
                '        <Annotation Term="SAP__capabilities.FilterRestrictions">',
                "          <Record>",
                '            <PropertyValue Property="Filterable" Bool="true"/>',
                "          </Record>",
                "        </Annotation>",
                '        <Annotation Term="SAP__capabilities.SortRestrictions">',
                "          <Record>",
                '            <PropertyValue Property="Sortable" Bool="true"/>',
                "          </Record>",
                "        </Annotation>",
                '        <Annotation Term="SAP__capabilities.CountRestrictions">',
                "          <Record>",
                '            <PropertyValue Property="Countable" Bool="true"/>',
                "          </Record>",
                "        </Annotation>",
            ]
        )
        lines.append("      </Annotations>")

    for target in digit_targets:
        lines.append(f'      <Annotations Target="SAP__self.{target}">')
        lines.append('        <Annotation Term="SAP__common.IsDigitSequence"/>')
        lines.append("      </Annotations>")

    lines.extend(
        [
            "    </Schema>",
            "  </edmx:DataServices>",
            "</edmx:Edmx>",
            "",
        ]
    )
    path = OUT / f"{service_name}.xml"
    path.write_text("\n".join(lines))
    ET.parse(path)
    return path, len(entities)


def main():
    for service_name in SERVICES:
        path, count = render(service_name)
        print(f"{path.name}: {count} entity sets")


if __name__ == "__main__":
    main()
