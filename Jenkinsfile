// Daily propagation of the PM Szczecin schedule into the production Supabase.
//
// The pipeline is deliberately split: scraping runs first and touches nothing,
// a sanity gate inspects the parsed artifact, and only then does the
// destructive load (json2db clears the classes table before inserting) run.
// An unattended daily job must never wipe production on a bad scrape.
//
// Credentials expected in Jenkins (Manage Jenkins -> Credentials), as Secret text:
//   planpm-supabase-url          -> SUPABASE_URL          (prod project URL)
//   planpm-supabase-service-key  -> SUPABASE_SERVICE_KEY  (prod service_role key)
//   planpm-discord-webhook       -> DISCORD_WEBHOOK_URL   (optional; absent = no embeds,
//                                   probed at Checkout and bound only where present)

pipeline {
    // Pinned, not `agent any`: this job assumes Homebrew under /opt/homebrew and
    // uv on the controller's PATH. Jenkins currently has no agent nodes, so the
    // two are the same thing today — but the day one is attached, `any` would
    // start scheduling production database writes onto whichever machine was
    // free. `built-in` is the controller's own self-label.
    agent { label 'built-in' }

    triggers {
        // Daily at 04:0x local time, every month except July and August.
        // The university publishes nothing over the summer break, so a run then
        // would scrape an empty/near-empty schedule, trip the sanity gate and
        // fail the build every single day. H spreads load across the hour.
        // Manual "Build Now" still works in July/August if ever needed.
        cron('H 4 * 1-6,9-12 *')
    }

    parameters {
        booleanParam(
            name: 'DRY_RUN',
            defaultValue: false,
            description: 'Scrape and validate, then print what would be written without touching the database.'
        )
        booleanParam(
            name: 'SKIP_SANITY_GATE',
            defaultValue: false,
            description: 'DANGEROUS. Load even if the scrape returned far fewer classes than production currently holds. Only after manually inspecting the archived parser.json.'
        )
        string(
            name: 'MAX_DROP_PERCENT',
            defaultValue: '30',
            description: 'Abort if the scraped class count is more than this percentage below the live production count.'
        )
    }

    options {
        // A second run must never overlap the first: json2db clears the table.
        disableConcurrentBuilds()
        timeout(time: 45, unit: 'MINUTES')
        buildDiscarder(logRotator(numToKeepStr: '30', artifactNumToKeepStr: '30'))
        timestamps()
    }

    environment {
        // The Jenkins LaunchAgent inherits a bare PATH (/usr/bin:/bin:/usr/sbin:/sbin),
        // so Homebrew binaries — uv above all — are invisible to `sh` steps without this.
        PATH             = "/opt/homebrew/bin:${PATH}"

        // Read at import time by json2db, so it must be set before python starts.
        // Takes precedence over the .env_mode file, which is not checked out here.
        PLANPM_ENV       = 'prod'
        PYTHONUTF8       = '1'
        PYTHONIOENCODING = 'utf-8'
        PYTHONUNBUFFERED = '1'
        VENV             = "${WORKSPACE}/backend/.venv"
        PY               = "${WORKSPACE}/backend/.venv/bin/python"
    }

    stages {
        stage('Checkout') {
            steps {
                checkout scm
                script {
                    // Resolved once and reused: every later binding is conditional
                    // on it, and probing per stage would only repeat the lookup.
                    env.HAS_DISCORD_WEBHOOK = webhookConfigured().toString()
                    if (env.HAS_DISCORD_WEBHOOK != 'true') {
                        echo 'planpm-discord-webhook is not configured — this build will not send Discord embeds.'
                    }
                    // No stage has run yet, so nothing has reported for itself.
                    env.STEP_REPORTED_ITSELF = 'false'
                }
            }
        }

        stage('Set up Python') {
            steps {
                dir('backend') {
                    // uv resolves from uv.lock, so the job pins the same versions
                    // the repo was tested with, and it provisions the interpreter
                    // itself. That last part is not optional here: pyproject needs
                    // Python >=3.13 while this machine's system python3 is 3.9.6,
                    // so a venv+pip fallback could never satisfy requires-python.
                    sh '''
                        set -eu
                        if ! command -v uv >/dev/null 2>&1; then
                            echo "uv not found on PATH ($PATH)." >&2
                            echo "Install it with: brew install uv" >&2
                            exit 1
                        fi
                        uv sync --frozen
                        "$PY" --version
                    '''
                }
            }
        }

        stage('Scrape') {
            steps {
                dir('backend') {
                    // Same invocations the admin panel uses (admin/routes/pipeline.py),
                    // so there is one definition of each step. None of these touch
                    // the database.
                    sh '''
                        set -eu
                        "$PY" -c "from mapper import Mapper; Mapper(output='./output/mapper.json').run(minID=0, maxID=600)"
                        "$PY" -c "from scrapper import HttpScrapper; HttpScrapper(input='./output/mapper.json', output='./output/scrapper.json').run()"
                        "$PY" -c "from parser import Parser; Parser(input='scrapper.json').run()"
                    '''
                }
            }
        }

        stage('Sanity gate') {
            steps {
                dir('backend') {
                    withCredentials(supabaseBindings()) {
                        // json2db has its own MIN_CLASSES_TO_CLEAR=100 floor, but 100
                        // is far below a healthy scrape (~3600). If the university
                        // site half-breaks and returns 200 rows, that floor passes and
                        // production gets wiped. Compare against the live count instead.
                        sh '''
                            set -eu
                            SKIP_GATE="''' + '${SKIP_SANITY_GATE}' + '''" \
                            MAX_DROP="''' + '${MAX_DROP_PERCENT}' + '''" \
                            "$PY" - <<'PY'
import json, os, sys

with open("./output/parser.json", encoding="utf-8") as f:
    scraped = len(json.load(f)["classes"])

from supabase import create_client
sb = create_client(os.environ["SUPABASE_URL"], os.environ["SUPABASE_SERVICE_KEY"])
live = sb.table("classes").select("id", count="exact").limit(1).execute().count or 0

max_drop = float(os.environ.get("MAX_DROP", "30"))
floor = int(live * (1 - max_drop / 100))
print(f"scraped={scraped} live={live} floor={floor} (max drop {max_drop}%)")

if scraped < floor:
    msg = f"Scrape returned {scraped} classes, below the {floor} floor derived from {live} live rows."
    if os.environ.get("SKIP_GATE") == "true":
        print(f"GATE OVERRIDDEN: {msg}", file=sys.stderr)
    else:
        sys.exit(f"ABORT: {msg} Inspect the archived parser.json, then re-run with SKIP_SANITY_GATE if the drop is genuine.")
print("Sanity gate passed.")
PY
                        '''
                    }
                }
            }
        }

        // Classes load BEFORE the structure is refreshed, and the order is the
        // whole point. These are two independent destructive writes with no
        // shared transaction, so one of them can land without the other; what
        // differs is what a student sees in the meantime.
        //   load first, structure stale  -> a newly opened specialisation is not
        //       yet selectable. That is the status quo of any day before the
        //       university renamed anything, and Structure check reports it.
        //   structure first, load failed -> the dropdowns offer combinations
        //       backed by stale or empty classes: the app looks broken.
        // The second is strictly worse, so the reversible-looking step goes last.
        stage('Load into production') {
            steps {
                dir('backend') {
                    // json2db notifies Discord itself on this path, so
                    // PLANPM_NOTIFY_HANDLED is deliberately left unset — and so
                    // post{failure} must not add a second embed for this stage.
                    script {
                        env.STEP_REPORTED_ITSELF = 'true'
                    }
                    withCredentials(supabaseBindings() + discordBinding()) {
                        script {
                            def dryRun = params.DRY_RUN ? '--dry-run' : ''
                            sh """
                                set -eu
                                "\$PY" -m json2db.json2db --input ./output/parser.json --clear ${dryRun}
                            """
                        }
                    }
                }
            }
        }

        stage('Refresh structure') {
            steps {
                dir('backend') {
                    // structure_updater notifies Discord itself, success and
                    // failure alike, so this stage owns its own reporting too.
                    script {
                        env.STEP_REPORTED_ITSELF = 'true'
                    }
                    withCredentials(supabaseBindings() + discordBinding()) {
                        // The app builds its dropdowns from these tables. Left unrun,
                        // a specialisation the university opens mid-year is simply not
                        // selectable — that is how "Logistyka Transportu Zintegrowanego"
                        // was missing for four months. structure_updater has its own
                        // floor (2 faculties / 5 degree courses) before it clears.
                        script {
                            def dryRun = params.DRY_RUN ? '--dry-run' : ''
                            sh """
                                set -eu
                                "\$PY" -m structure_updater.structure_updater ${dryRun}
                            """
                        }
                    }
                }
            }
        }

        stage('Structure check') {
            steps {
                dir('backend') {
                    // structure_check only notifies about names it could not
                    // match; it says nothing when it crashes, so a failure here
                    // is post{failure}'s to report.
                    script {
                        env.STEP_REPORTED_ITSELF = 'false'
                    }
                    withCredentials(supabaseBindings() + discordBinding()) {
                        // Every published plan must be reachable from the app's
                        // dropdowns. Deliberately not --strict: the data is loaded and
                        // correct, it is a name that drifted, and a red build every
                        // morning would train everyone to ignore it. The Discord ping
                        // is the signal.
                        sh '''
                            set -eu
                            "$PY" -m structure_check.structure_check
                        '''
                    }
                }
            }
        }
    }

    post {
        always {
            // Keep the artifacts even on failure: the sanity gate tells you to
            // inspect parser.json, which is only useful if it survives the build.
            archiveArtifacts artifacts: 'backend/output/*.json, backend/logs/*.log',
                             allowEmptyArchive: true,
                             fingerprint: false
        }
        failure {
            // This is the fallback reporter, for the stages that say nothing for
            // themselves: Checkout, Set up Python, Scrape, Sanity gate and
            // Structure check. json2db and structure_updater both notify from
            // their own `finally`, so reporting here as well produced two embeds
            // for one failure — the flag is how a stage says "already handled".
            script {
                if (env.STEP_REPORTED_ITSELF == 'true') {
                    echo 'The failed stage already sent its own Discord embed; not sending a second one.'
                } else if (env.HAS_DISCORD_WEBHOOK == 'true') {
                    withCredentials([string(credentialsId: 'planpm-discord-webhook', variable: 'DISCORD_WEBHOOK_URL')]) {
                        dir('backend') {
                            sh '''
                                set +e
                                "$PY" -c "
from notifier import notify_discord
notify_discord('Daily propagation', success=False,
               detail='Jenkins build ''' + '${BUILD_NUMBER}' + ''' failed before or during the DB load. See ''' + '${BUILD_URL}' + '''',
               env='prod')
" || true
                            '''
                        }
                    }
                }
            }
        }
    }
}

// ---------------------------------------------------------------------------
// planpm-discord-webhook is documented as optional ("absent = no embeds"), but
// withCredentials raises CredentialNotFoundException before it ever enters the
// block. Binding it unconditionally therefore made the credential mandatory in
// practice: on a Jenkins without it, every stage below the sanity gate failed —
// and so did the post{failure} block trying to report that failure.
//
// Probe it once, with an empty body so nothing can happen inside the try but
// the binding itself, and bind it afterwards only where it exists.
// ---------------------------------------------------------------------------
def webhookConfigured() {
    try {
        withCredentials([string(credentialsId: 'planpm-discord-webhook', variable: 'PROBE')]) { }
        return true
    } catch (ignored) {
        return false
    }
}

def discordBinding() {
    return env.HAS_DISCORD_WEBHOOK == 'true'
        ? [string(credentialsId: 'planpm-discord-webhook', variable: 'DISCORD_WEBHOOK_URL')]
        : []
}

def supabaseBindings() {
    return [
        string(credentialsId: 'planpm-supabase-url', variable: 'SUPABASE_URL'),
        string(credentialsId: 'planpm-supabase-service-key', variable: 'SUPABASE_SERVICE_KEY')
    ]
}
