### Dataset Overview

The Chinook** database is a sample digital music store dataset that models the structure and operations of an online music retail platform (similar to iTunes). It contains realistic transactional data covering customers, invoices, tracks, albums, artists, genres, playlists, and employees.

This dataset is widely used for learning SQL, business intelligence, data analysis, and database design.

### Source
- **Original Author**: Luis Rocha  
- **Version**: 1.4.5  
- **License**: Available under the Chinook Database license (open for educational and personal use)  
- **Format**: MySQL script (`Chinook_MySql.sql`)

### Key Tables
| Table            | Description                                      |
|------------------|--------------------------------------------------|
| `Customer`       | Customer details and support representative      |
| `Invoice`        | Sales transactions                               |
| `InvoiceLine`    | Individual items purchased in each invoice       |
| `Track`          | Songs / media files                              |
| `Album`          | Music albums                                     |
| `Artist`         | Music artists                                    |
| `Genre`          | Music genres                                     |
| `MediaType`      | File formats (MPEG, AAC, etc.)                   |
| `Playlist`       | Curated playlists                                |
| `PlaylistTrack`  | Tracks belonging to playlists                    |
| `Employee`       | Store employees and hierarchy                    |

### Business Context
This dataset enables analysis of:
- Revenue trends over time
- Top-performing artists, albums, and tracks
- Customer purchasing behavior and lifetime value
- Genre preferences by country
- Cross-selling opportunities
- Playlist performance

### Ideal For
- SQL practice (SELECT, JOINs, GROUP BY, window functions, CTEs)
- Business intelligence & reporting projects
- Customer segmentation and RFM analysis
- Data visualization and dashboard creation
