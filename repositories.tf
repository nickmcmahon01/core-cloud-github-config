locals {
  repositories = {
    "core-cloud" = {
      visibility   = "public"
      description  = "SAS Core Cloud Documentation"
      homepage_url = "https://ukhomeoffice.github.io/core-cloud/"
    },
    "core-cloud-lza-config" = {
      visibility                    = "internal"
      description                   = "SAS Core Cloud LZA Config"
      include_pull_request_template = true
    },
    "core-cloud-github-config" = {
      visibility                    = "public"
      description                   = "GitHub repository configuration for Core Cloud repositories"
      include_pull_request_template = true
    },
    "core-cloud-add-customer-action" = {
      visibility  = "public"
      description = "GitHub Action to add a customer to the Core Cloud LZA config"

      checks = [
        "CodeQL",
        "Check dist/",
        "GitHub Actions Test",
        "Lint Codebase",
        "Semver Check PR Label / Calculate SemVer Value",
        "TypeScript Tests"
      ]
    },
    "core-cloud-lza-iam-terraform" = {
      visibility  = "internal"
      description = "Terraform module for creating and handling Identity Center groups, users, permission sets, assignments, and memberships"
    },
    "semver-calculate-action" = {
      visibility  = "public"
      description = "GitHub Action that increments SemVer values"

      checks = [
        "check / Calculate SemVer Value",
        "diff / Diff Dist (20.x)",
        "test / Unit and Integration Tests (20.x)",
      ]
    },
    "semver-tag-action" = {
      visibility  = "public"
      description = "GitHub Action that increments and tags SemVer"

      checks = [
        "check / Calculate SemVer Value",
        "diff / Diff Dist (20.x)",
        "test / Unit and Integration Tests (20.x)",
      ]
    },
    "match-label-action" = {
      visibility  = "public"
      description = "GitHub action that supports the enforcing of labels on Pull Requests"

      checks = [
        "check / Calculate SemVer Value",
        "diff / Diff Dist (20.x)",
        "test / Unit and Integration Tests (20.x)",
      ]
    }
  }
}

resource "github_repository" "core_cloud_repositories" {
  for_each               = local.repositories
  name                   = each.key
  description            = each.value.description
  visibility             = each.value.visibility
  has_issues             = false
  has_projects           = false
  has_wiki               = false
  has_downloads          = false
  allow_merge_commit     = false
  allow_squash_merge     = true
  allow_rebase_merge     = false
  allow_update_branch    = true
  allow_auto_merge       = true
  delete_branch_on_merge = true
  homepage_url           = try(each.value.homepage_url, null)

  lifecycle {
    prevent_destroy = true

    ignore_changes = [
      pages
    ]
  }
}

resource "github_team_repository" "core_cloud_admin_team_repositories" {
  for_each   = github_repository.core_cloud_repositories
  repository = each.key
  team_id    = data.github_team.core_cloud_admin.id
  permission = "admin"

  lifecycle {
    prevent_destroy = true
  }
}

resource "github_team_repository" "core_cloud_devops_team_repositories" {
  for_each   = github_repository.core_cloud_repositories
  repository = each.key
  team_id    = data.github_team.core_cloud_devops.id
  permission = "push"

  lifecycle {
    prevent_destroy = true
  }
}

resource "github_branch_protection" "main" {
  for_each      = github_repository.core_cloud_repositories
  repository_id = each.key

  pattern                         = "main"
  enforce_admins                  = true
  required_linear_history         = true
  require_conversation_resolution = true
  require_signed_commits          = true
  allows_force_pushes             = false
  allows_deletions                = false

  required_pull_request_reviews {
    require_last_push_approval      = true
    required_approving_review_count = 1
  }

  required_status_checks {
    strict   = true
    contexts = try(local.repositories[each.value.name].checks, [])
  }

  lifecycle {
    prevent_destroy = false
  }
}

resource "github_actions_repository_permissions" "core_cloud_repositories" {
  for_each   = github_repository.core_cloud_repositories
  repository = each.key

  allowed_actions = "selected"
  enabled         = true

  allowed_actions_config {
    github_owned_allowed = true
    verified_allowed     = false
    patterns_allowed = [
      "aws-actions/*",
      "hashicorp/*",
      "slackapi/*",
      "super-linter/super-linter/*"
    ]
  }

  lifecycle {
    prevent_destroy = true
  }
}
