Feature: Product Owner Epic
  As a product owner
  I want to manage epic details and priority
  So that i can plan on higher abstraction level

  Background:
    Given the ecookbook project has the backlogs plugin enabled
      And no versions or issues exist
      And I am a product owner of the project
      And I have defined the following sprints:
        | name       | sprint_start_date | effective_date |
        | Sprint 001 | 2010-01-01        | 2010-01-31     |
        | Sprint 002 | 2010-02-01        | 2010-02-28     |
      And I have deleted all existing issues
      And I have defined the following epics in the product backlog:
        | subject |
        | Epic 1 |
      And I have defined the following stories in the product backlog:
        | subject |
        | Story 1 |
        | Story 2 |
        | Story 3 |
        | Story 4 |
      And I have defined the following stories in the following sprints:
        | subject | sprint     |
        | Story A | Sprint 001 |
        | Story B | Sprint 001 |

  Scenario: View the product backlog
    Given I am viewing the master backlog
     Then I should see the product backlog
      And I should see 4 stories in the product backlog
      And I should see 2 sprint backlogs
    Given I am viewing the epic backlog
     Then I should see 1 epics in the epic backlog

  Scenario: Create a new Epic
    Given I am viewing the epic backlog
      And I want to create an epic
      And I set the subject of the epic to A Whole New Epic
     When I create the epic
     Then the request should complete successfully
      And the 1st epic in the product backlog should be A Whole New Epic

  Scenario: Update a Epic
    Given I am viewing the epic backlog
      And I want to edit the epic with subject Epic 1
      And I set the subject of the epic to Patrick was here
     When I update the epic
     Then the request should complete successfully
      And the epic should have a subject of Patrick was here
      And the epic should be at position 1

  Scenario: View the epic board
    Given I am viewing the epicboard
