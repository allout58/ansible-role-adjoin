local Converge(distro) = {
  name: "Converge - "+distro,
  image: "registry.element-networks.nl/tools/molecule",
  commands: [
    "molecule destroy",
    "molecule converge",
    "molecule idempotence",
    "molecule verify",
    "molecule destroy",
  ],
  environment:
    { MOLECULE_DISTRO: +distro, },
  privileged: true,
  volumes: [
    { name: "docker", path: "/var/run/docker.sock" },
  ],
};

[
  {
    name: "Lint",
    kind: "pipeline",
    steps: [
      {
        name: "Lint code",
        image: "registry.element-networks.nl/tools/molecule",
        commands: [
          "molecule lint",
          "molecule syntax"
        ]
      }
    ],
    volumes: [
      { name: "docker",
        host: { path: "/var/run/docker.sock" }
      },
    ],
  },
  {
    kind: "pipeline",
    name: "Test",
    steps: [
      Converge("debian10"),
      Converge("debian9"),
      Converge("centos7"),
      Converge("ubuntu1804"),
    ],
    volumes: [
      { name: "docker",
        host: { path: "/var/run/docker.sock" }
      },
    ],
    depends_on: [
      "Lint",
    ],
  },
  {
    name: "Publish",
    kind: "pipeline",
    clone:
      { disable: true },
    steps: [
      {
        name: "Ansible Galaxy",
        image: "registry.element-networks.nl/tools/molecule",
        commands: [
          "ansible-galaxy login --github-token $$GITHUB_TOKEN",
          "ansible-galaxy import Thulium-Drake ansible-role-adjoin --role-name=adjoin",
        ],
        environment:
          { GITHUB_TOKEN: { from_secret: "github_token" } },
      },
    ],
    depends_on: [
      "Test",
    ],
  },
]
