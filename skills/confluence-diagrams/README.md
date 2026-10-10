# Confluence diagrams

Use `confluence-diagrams` when Mermaid source must appear as an image on a Confluence Cloud page. The guide also covers pages that display source text, broken images, or cropped diagrams after publication.

The workflow checks for an available renderer and a tool that can transmit actual image bytes as a page attachment. It then places the attachment through a documented page-editing method and checks the published page. A local render or a filename passed to a text-only interface does not count as an uploaded image.

The guide is self-contained. It does not assume a specific Confluence client or Mermaid command. When permissions, a binary upload path, or published-page access are missing, the agent reports the blocked step instead of claiming success.
