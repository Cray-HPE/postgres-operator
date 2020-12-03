@Library("dst-shared@release/shasta-1.4") _

dockerBuildPipeline {
        repository = "cray"
        dockerfile = "./docker/Dockerfile"
        buildPrepScript = "buildPrep.sh"
        dockerBuildContextDir = "."
        app = "postgres-operator"
        name = "postgres-operator"
        description = "Forked Postgres Operator"
        useEntryPointForTest = "false"
        product = "csm"
}
