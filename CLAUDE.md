# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code)
when working with code in this repository.

## Code Quality Rules

After editing any Markdown file, fix all markdownlint issues
before finishing.

## Project Overview

SurveyMoonbear is a Ruby web application for creating surveys
from Google Sheets. Users log in via Google OAuth, create
surveys backed by Google Spreadsheets, launch them for
respondents, and analyze responses with reports and learning
analytics dashboards.

**Stack:** Ruby 3.3.5, Roda web framework, Sequel ORM,
PostgreSQL (prod) / SQLite (dev/test), Sidekiq for background
jobs, Slim templates, Redis for sessions/cache.

## Common Commands

```bash
rake run:dev               # Start dev server (Puma + Sidekiq)
rake spec                  # Run integration tests
rake respec                # Watch mode: rerun tests on changes
rake db:migrate            # Run database migrations
rake db:wipe               # Clear all table records
rake db:drop               # Delete SQLite DB (dev/test only)
rake console               # Pry REPL with app loaded
rake vcr:delete            # Clear VCR cassettes
rake crypto:db_key         # Generate DB encryption key
rake crypto:msg_key        # Generate message encryption key
rake crypto:session_secret # Generate session secret
```

Tests are Minitest integration tests in
`spec/tests_integration/`. VCR records HTTP interactions as
cassettes in `spec/fixtures/cassettes/`. Code quality:
`rubocop`, `reek`, `flog`.

## Architecture

This is **not Rails**. It uses a layered hexagonal architecture
with four distinct layers:

```text
presentation/   → Slim views, CSS/JS assets, view objects
application/    → Roda routing + Dry::Transaction services
domain/         → Entities (Dry::Struct), repositories, mappers
infrastructure/ → Sequel ORM, Google APIs, AWS SNS, Redis cache
```

Initialization loads layers in order via `init.rb`:
lib → config → infrastructure → domain → application →
presentation.

### Routing

All HTTP routing is in `application/controllers/app.rb`
(single large Roda routing tree). The app class is
`SurveyMoonbear::App < Roda`. Entry point: `config.ru` maps
`/` to the Roda app and `/sidekiq` to Sidekiq::Web.

### Services (Application Layer)

Business logic lives in `application/services/` organized by
domain area (surveys, studies, responses, etc.). Services use
`Dry::Transaction` with step-based composition:

```ruby
class CreateSurvey
  include Dry::Transaction
  include Dry::Monads
  step :refresh_access_token
  step :copy_sample_spreadsheet
  step :store_belongs_study
end
```

Each step returns `Success(input)` or `Failure(message)`.
Services are called from routes as
`Service::CreateSurvey.new.call(config:, current_account:)`.

### Domain Entities

Entities in `domain/entities/` are immutable `Dry::Struct`
value objects (Account, Survey, Study, Launch, Page, Item,
Response, Participant, Notification, Event, VisualReport).

### Repository Pattern

`domain/database_repositories/` contains repository classes
accessed via `Repository::For[Entity::Survey]`. Repositories
bridge domain entities and Sequel ORM models.

### ORM

Sequel ORM models live in `infrastructure/database/orm/`.
Migrations in `infrastructure/database/migrations/` (001-015).
Database connection set up in `config/environments.rb` via
`Sequel.connect(ENV['DATABASE_URL'])`.

### Google Integration

`infrastructure/google/` handles OAuth token refresh, Google
Sheets/Drive API calls, and Google Calendar. Surveys are stored
in both Google Sheets (as source of truth for structure) and
the database. `domain/google_mappers/` transforms Sheets data
into domain entities.

### Background Workers

Sidekiq workers in `workers/workers.rb`, scheduled via
`workers/sidekiq_scheduler.yml`. Used for notification
scheduling and survey response processing.

## Configuration

Environment variables managed by Figaro (`config/secrets.yml`).
Key vars: `GOOGLE_CLIENT_ID`, `GOOGLE_CLIENT_SECRET`,
`REFRESH_TOKEN`, `SAMPLE_FILE_ID`, `DB_FILENAME`, `DB_KEY`,
`SESSION_SECRET`, `MSG_KEY`, `REDISCLOUD_SIDEKIQ_QUEUES_URL`,
`REDISCLOUD_VISUALREPORTS_URL`.

Dev/test use `Rack::Session::Pool` + file-based Rack::Cache.
Production uses `Rack::Session::Redis` + Redis-backed
Rack::Cache.

## Key Domain Relationships

- **Account** owns many Surveys
- **Study** groups Surveys, has Participants and Notifications
- **Survey** has Pages, each with Items (questions);
  has Launches (active instances)
- **Launch** collects Responses from respondents
- **Notification** integrates with AWS SNS for participant
  reminders

## Security

Sensitive DB fields encrypted via `lib/secure_db.rb` (rbnacl).
Sessions via `lib/secure_session.rb`. Messages via
`lib/secure_message.rb`. Production enforces HTTPS via
`rack-ssl-enforcer`, rate limiting via `rack-attack`, security
headers via `secure_headers`.

## Existing Documentation

The `doc/` directory contains detailed guides organized by
topic. Consult these before making changes in unfamiliar areas:

### Architecture & Design (`doc/architecture/`)

- `architecture-intro.md` — System architecture overview
  and diagram references
- `services.md` — Catalog of all application services by
  domain area (auth, outputs, responses, surveys)
- `infrastructure.md` — Database schema, Google
  Sheets/Drive integration, AWS SQS, concurrency design
- `client-side-browser-application.md` — Client-side URL
  routing, view file mappings, and service call flows

### Setup & Development

- `doc/getting_start.md` — Local setup: cloning, gems,
  secrets.yml, migrations, troubleshooting
- `doc/test_code.md` — Running integration tests, VCR
  cassette management

### Google Integration (`doc/google/`)

- `google_drive_api.md` — GCP project setup, enabling
  Drive/Sheets APIs, OAuth credentials, refresh tokens
- `applying_google_oauth_verification.md` — Google OAuth
  verification process and privacy policy requirements

### Deployment

- `doc/heroku/staging_app.md` — Creating Heroku staging
  apps with PostgreSQL
- `doc/heroku/update_from_github.md` — Deploying from
  GitHub master to Heroku production
- `doc/heroku/test_on_heroku_new_stack.md` — Testing on
  new Heroku stacks, migrating add-ons
- `doc/heroku/pgAdmin_remote_connection.md` — Connecting
  pgAdmin to remote Heroku PostgreSQL
- `doc/docker/docker_project.md` — Dockerfile setup,
  building and running containers
- `doc/aws/sqs.md` — AWS SQS queue setup and message
  publishing/receiving

### User Guide (`doc/user_guide/`)

- `question_type.md` — All supported question types
  (short answer, multiple choice, grids, sliders, VAS,
  flow logic)
- `insert_image.md` / `insert_video.md` — Embedding
  images and YouTube videos in surveys
- `embedded_variable.md` — Using `{{}}` variable syntax
  in survey questions
- `survey_group.md` — Respondent grouping via URL params
- `competitive_products.md` — Feature comparison with
  Google Forms, SurveyMonkey, SurveyCake

### Other

- `doc/brainstorming/upcoming_features.md` — Feature
  roadmap and completed feature checklist
- `doc/image_guide/naming_convention.md` — Naming
  conventions for documentation images
