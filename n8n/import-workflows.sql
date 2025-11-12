-- LandBase AI Suite: n8n Sample Workflows
-- This script inserts sample workflows into n8n database

-- Sample Workflow 1: Hello World
INSERT INTO workflow_entity (
    id,
    name,
    active,
    nodes,
    connections,
    "createdAt",
    "updatedAt",
    settings,
    "staticData",
    "pinData",
    "versionId",
    "triggerCount"
) VALUES (
    'a1b2c3d4-e5f6-7890-abcd-ef1234567890',
    'Sample Workflow 1: Hello World',
    false,
    '[
        {
            "parameters": {},
            "id": "node1",
            "name": "When clicking Test workflow",
            "type": "n8n-nodes-base.manualTrigger",
            "typeVersion": 1,
            "position": [250, 300]
        },
        {
            "parameters": {
                "values": {
                    "string": [
                        {
                            "name": "message",
                            "value": "Hello from LandBase AI Suite!"
                        },
                        {
                            "name": "timestamp",
                            "value": "={{ $now.toISO() }}"
                        }
                    ]
                },
                "options": {}
            },
            "id": "node2",
            "name": "Set Message",
            "type": "n8n-nodes-base.set",
            "typeVersion": 3,
            "position": [450, 300]
        }
    ]'::json,
    '{
        "When clicking Test workflow": {
            "main": [
                [
                    {
                        "node": "Set Message",
                        "type": "main",
                        "index": 0
                    }
                ]
            ]
        }
    }'::json,
    CURRENT_TIMESTAMP,
    CURRENT_TIMESTAMP,
    '{"executionOrder": "v1"}'::json,
    NULL,
    '{}'::json,
    '1',
    0
) ON CONFLICT (id) DO NOTHING;

-- Sample Workflow 2: PostgreSQL Test
INSERT INTO workflow_entity (
    id,
    name,
    active,
    nodes,
    connections,
    "createdAt",
    "updatedAt",
    settings,
    "staticData",
    "pinData",
    "versionId",
    "triggerCount"
) VALUES (
    'b2c3d4e5-f6a7-8901-bcde-f12345678901',
    'Sample Workflow 2: PostgreSQL Test',
    false,
    '[
        {
            "parameters": {},
            "id": "node1",
            "name": "When clicking Test workflow",
            "type": "n8n-nodes-base.manualTrigger",
            "typeVersion": 1,
            "position": [250, 300]
        },
        {
            "parameters": {
                "operation": "executeQuery",
                "query": "SELECT version() as db_version, current_database() as db_name, current_user as db_user",
                "options": {}
            },
            "id": "node2",
            "name": "PostgreSQL Query",
            "type": "n8n-nodes-base.postgres",
            "typeVersion": 2,
            "position": [450, 300],
            "credentials": {
                "postgres": {
                    "id": "1",
                    "name": "LandBase PostgreSQL"
                }
            }
        }
    ]'::json,
    '{
        "When clicking Test workflow": {
            "main": [
                [
                    {
                        "node": "PostgreSQL Query",
                        "type": "main",
                        "index": 0
                    }
                ]
            ]
        }
    }'::json,
    CURRENT_TIMESTAMP,
    CURRENT_TIMESTAMP,
    '{"executionOrder": "v1"}'::json,
    NULL,
    '{}'::json,
    '1',
    0
) ON CONFLICT (id) DO NOTHING;

-- Sample Workflow 3: API Integration
INSERT INTO workflow_entity (
    id,
    name,
    active,
    nodes,
    connections,
    "createdAt",
    "updatedAt",
    settings,
    "staticData",
    "pinData",
    "versionId",
    "triggerCount"
) VALUES (
    'c3d4e5f6-a7b8-9012-cdef-123456789012',
    'Sample Workflow 3: API Integration',
    false,
    '[
        {
            "parameters": {},
            "id": "node1",
            "name": "When clicking Test workflow",
            "type": "n8n-nodes-base.manualTrigger",
            "typeVersion": 1,
            "position": [250, 300]
        },
        {
            "parameters": {
                "url": "https://api.github.com/repos/n8n-io/n8n",
                "options": {}
            },
            "id": "node2",
            "name": "HTTP Request",
            "type": "n8n-nodes-base.httpRequest",
            "typeVersion": 4,
            "position": [450, 300]
        },
        {
            "parameters": {
                "values": {
                    "string": [
                        {
                            "name": "repository",
                            "value": "={{ $json.full_name }}"
                        },
                        {
                            "name": "stars",
                            "value": "={{ $json.stargazers_count }}"
                        },
                        {
                            "name": "description",
                            "value": "={{ $json.description }}"
                        }
                    ]
                },
                "options": {}
            },
            "id": "node3",
            "name": "Extract Data",
            "type": "n8n-nodes-base.set",
            "typeVersion": 3,
            "position": [650, 300]
        }
    ]'::json,
    '{
        "When clicking Test workflow": {
            "main": [
                [
                    {
                        "node": "HTTP Request",
                        "type": "main",
                        "index": 0
                    }
                ]
            ]
        },
        "HTTP Request": {
            "main": [
                [
                    {
                        "node": "Extract Data",
                        "type": "main",
                        "index": 0
                    }
                ]
            ]
        }
    }'::json,
    CURRENT_TIMESTAMP,
    CURRENT_TIMESTAMP,
    '{"executionOrder": "v1"}'::json,
    NULL,
    '{}'::json,
    '1',
    0
) ON CONFLICT (id) DO NOTHING;

-- Get the first project ID (personal project)
DO $$
DECLARE
    project_id_var VARCHAR(36);
BEGIN
    SELECT id INTO project_id_var FROM project LIMIT 1;

    -- Share workflows with the project
    INSERT INTO shared_workflow ("workflowId", "projectId", role, "createdAt", "updatedAt")
    VALUES
        ('a1b2c3d4-e5f6-7890-abcd-ef1234567890', project_id_var, 'workflow:owner', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
        ('b2c3d4e5-f6a7-8901-bcde-f12345678901', project_id_var, 'workflow:owner', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
        ('c3d4e5f6-a7b8-9012-cdef-123456789012', project_id_var, 'workflow:owner', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
    ON CONFLICT ("workflowId", "projectId") DO NOTHING;
END $$;

-- Display result
SELECT '✅ Sample workflows imported successfully!' as message;
SELECT COUNT(*) as total_workflows FROM workflow_entity;
