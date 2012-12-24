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

  Scenario: Create a new Epic
    Given I am viewing the master backlog
      And I want to create an epic
      And I set the subject of the epic to A Whole New Epic
     When I create the epic
     Then the request should complete successfully
      And the 1st epic in the product backlog should be A Whole New Epic
