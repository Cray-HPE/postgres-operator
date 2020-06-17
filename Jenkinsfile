@Library('dst-shared') _

dockerBuildPipeline {
        repository = "cray"
        dockerfile = "./docker/Dockerfile"
        buildPrepScript = "buildPrep.sh"
        dockerBuildContextDir = "."
        app = "postgres-operator"
        name = "postgres-operator"
        description = "Forked Postgres Operator"
        useEntryPointForTest = "false"
        product = "shasta-standard,shasta-premium"
}
