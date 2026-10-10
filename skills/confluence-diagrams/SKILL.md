---
name: confluence-diagrams
description: Use when Mermaid diagrams on a Confluence Cloud page must appear as images, or published diagrams show source text, fail to render, or appear clipped.
---

# Confluence diagrams

## When to use

Use this guide for a Confluence Cloud page that needs a Mermaid diagram displayed as an image. It also applies when an existing published page shows Mermaid source instead of a diagram, or an attached diagram is cropped.

## Procedure

1. Identify the target page, the Mermaid source, the intended diagram placement, and whether the operator has permission to change the page. Record the current page and attachments; preserve unrelated content.
2. Inspect the tools available in the current environment. Find a Mermaid renderer that accepts the source and produces a local PNG or SVG file. Check documented options. Render the diagram, inspect the actual image, and adjust size or layout if text is illegible or content is cut off.
3. Find a Confluence Cloud attachment path with a verified way to transmit the image bytes. Read the tool's schema or help for required inputs and authentication. A text-only tool cannot carry an image simply because it accepts a filename or a base64 string. Base64 is suitable only if the tool explicitly documents decoding it into a binary attachment. If no binary-capable path is available, stop and report the missing capability; do not claim the diagram was attached.
4. With permission and a working binary path, upload the rendered file to the target page. Use the attachment identifier or URL returned by the service. Follow the page editor's documented image insertion mechanism to place that attachment at the requested position. Do not invent an endpoint or markup. Publish the page only when publication is authorized.

## Verification

Reopen the published page, not just the editor preview. Confirm the image appears at the intended position and displays the diagram rather than Mermaid text, a broken image icon, or an attachment link alone. Check the full diagram, labels, and edges for clipping at normal page width. Report the page, the observed result, and any limits on verification. If the page cannot be published or reopened, report the work as unverified rather than complete.

## Limits

A renderer without an attachment path can produce a local file but cannot complete publication. Do not substitute an unverified third-party service or expose private diagram content to one without authorization. If authentication, permissions, rendering, binary upload, or published-page inspection is unavailable, state which step is blocked and what was actually completed.
