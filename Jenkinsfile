
pipeline {
    agent any
    
    environment {
        PACKER_AMI_ID = '' // Initialize PACKER_AMI_ID environment variable
        LATEST_TAG = null // Initialize LATEST_TAG environment variable as null
    }
    
    stages {
        stage('Clone Repository') {
            steps {
                // Perform a shallow clone
            git branch: 'main',
            url: 'https://github.com/shreya0522/c-360-final.git'
            }
        }
        
        stage('Fetch Latest Tag') {
            steps {
                script {
                    // Fetch all tags from the Git repository
                    sh 'git fetch --tags'
                    
                    // Get the list of tags sorted by commit date in descending order
                    def tagList = sh(script: 'git tag --sort=-creatordate', returnStdout: true).trim().split('\n')
                    
                    // Extract the latest tag
                    LATEST_TAG = tagList.head()
                    
                    echo "Latest tag: ${LATEST_TAG}"
                }
            }
        }
        
        stage('Checkout Latest Tag') {
            steps {
                script {
                    // Checkout the code from the latest tag
                    checkout([$class: 'GitSCM', branches: [[name: "${LATEST_TAG}"]], userRemoteConfigs: [[url: 'https://github.com/shreya0522/c-360-final.git']]])
                }
            }
        }
        
      stage('Run Build Init') {
            steps {
                script {
          // Run Packer build and capture the AMI ID from the output file
           sh 'packer init .' 
           sh 'packer build . | tee packer-output.txt' // Output Packer build output to a file
            def packerOutput = readFile('packer-output.txt') // Read the output from the file
            def matcher = (packerOutput =~ /AMIs were created:[^\n]*\n[^\n]*: ([^\n]*)/)
            PACKER_AMI_ID = matcher.find() ? matcher.group(1) : ''
            // Store the matched AMI ID in PACKER_AMI_ID, or set it to an empty string if no match is found
               }
            }
        }
        
        stage('Use AMI') {
            steps {
                // Access the AMI ID from the environment variable and use it
                script {
                    echo "AMI ID: ${PACKER_AMI_ID}"
                    // Use the AMI ID in your next steps...
                }
            }
        }

        stage('Create Launch Template Version') {
            steps {
                  script {
            // Define a file to capture command output
            def outputFileName = "create-launch-template-version-output.txt"

            // Run the command to create launch template version and capture the output
            sh """
                aws ec2 create-launch-template-version \
                    --launch-template-name c360-asg \
                    --source-version 1 \
                    --version-description 'Version 3 with updated AMI' \
                    --launch-template-data '{ "ImageId": "${PACKER_AMI_ID}", "InstanceType": "t2.micro", "SecurityGroupIds": ["sg-0b5e0f78d652b53b8"] }' \
                    > ${outputFileName} 2>&1
            """

            // Read the output file
            def createVersionOutput = readFile(outputFileName).trim()

            // Print the output for debugging
            echo "Create Launch Template Version Output: ${createVersionOutput}"

            // Check if there was any error or warning in the output
            if (createVersionOutput.contains("error") || createVersionOutput.contains("warning")) {
                error "Error or warning occurred during launch template version creation:\n ${createVersionOutput}"
            }

            // Extract the version number from the output
            def versionMatcher = (createVersionOutput =~ /"VersionNumber"\s*:\s*(\d+)/)
            LAUNCH_TEMPLATE_VERSION = versionMatcher.find() ? versionMatcher.group(1) : ''

            // Echo the created version number
            echo "Created launch template version: ${LAUNCH_TEMPLATE_VERSION}"
                 }
            }
        }
        
        stage('Modify Launch Template') {
            steps {
                script {
                    sh "aws ec2 modify-launch-template --launch-template-name c360-asg --default-version ${LAUNCH_TEMPLATE_VERSION}"
                }
            }
        }
        
        stage('Update Auto Scaling Group') {
            steps {
                script {
                    sh "aws autoscaling update-auto-scaling-group --auto-scaling-group-name c360-asg --launch-template \"LaunchTemplateName=c360-asg,Version=${LAUNCH_TEMPLATE_VERSION}\""
                }
            }
        }

        stage('Confirm Latest Tag') {
            steps {
                script {
                    // Prompt the user with the latest tag and ask for confirmation
                    def userInput = input(
                        id: 'userInput',
                        message: "The latest tag is '${LATEST_TAG}'. Do you want to proceed?",
                        parameters: [
                            booleanParam(defaultValue: false, description: 'Confirm whether to proceed', name: 'Confirm')
                        ]
                    )
                    
                    if (!userInput) {
                        error("User chose not to proceed with the latest tag.")
                    }
                }
            }
        }

             stage('Start Instance Refresh') {
            steps {
                script {
                    sh 'aws autoscaling start-instance-refresh --auto-scaling-group-name c360-asg --preferences \'{"InstanceWarmup": 60, "MinHealthyPercentage": 50}\''
                }
            }
        }

    } 
} 
