# Reproducible experiments for Laboratory work 2

Run all commands from `L2.V27`. Docker Engine 27+ and Docker Compose v2 are
expected. The scripts never delete unrelated images or volumes.

## 1. Prepare upstream starter projects

```bash
chmod +x scripts/*.sh research/python/patch_numpy_endpoint.py
./scripts/run-research.sh
```

The public Python starter is cloned to `research/work/python`; the public Go
starter is cloned to `research/work/golang`. Both locations are ignored by Git
so the repository does not duplicate third-party source code.

## 2. Python: layer order and image size

```bash
cd research/work/python
../../../scripts/measure-build.sh python-naive ../../python/Dockerfile.naive .
# Make a harmless source change required by the assignment, e.g. add a comment
# to build/index.html. Then repeat the same command with a different tag.
../../../scripts/measure-build.sh python-layered ../../python/Dockerfile.layered .
# Make the same harmless source change and repeat.
../../../scripts/measure-build.sh python-alpine ../../python/Dockerfile.alpine .
```

For the NumPy experiment, first run:

```bash
cd ../../python
python3 patch_numpy_endpoint.py
cd ../work/python
cp ../../python/requirements-numpy.in requirements/numpy.in
../../../scripts/lock-python-requirements.sh . --numpy
../../../scripts/measure-build.sh python-numpy-debian ../../python/Dockerfile.numpy-debian .
../../../scripts/measure-build.sh python-numpy-alpine ../../python/Dockerfile.numpy-alpine .
```

The results are recorded as JSON and build logs in `L2.V27/results/`. Put those
actual values into the Word report rather than estimating them.

## 3. musl vs glibc DNS lookup

```bash
cd ../../
./scripts/run-dns-experiment.sh | tee results/dns.log
```

Compare the expanded query names and the response output. Alpine/musl and
Ubuntu/glibc do not have identical resolver search-domain behavior in every
case; the saved DNS log is the evidence for the conclusion.

## 4. Go: one stage, scratch, distroless

```bash
cd research/work/golang
../../../scripts/measure-build.sh go-single ../../golang/Dockerfile.single .
../../../scripts/measure-build.sh go-scratch ../../golang/Dockerfile.multi-scratch .
../../../scripts/measure-build.sh go-distroless ../../golang/Dockerfile.multi-distroless .
```

Inspect final images with `docker image inspect` and, where an image contains a
shell, `docker run --rm --entrypoint sh IMAGE`. `scratch` deliberately has no
shell or CA bundle: that is a property to explain, not a test failure.

## 5. Containerize mywebapp

```bash
cp .env.example .env
# Edit both passwords in .env to the same nonempty local-development value.
docker compose up -d --build --wait
./scripts/compose-smoke-test.sh
docker compose down
# Prove persistence: bring it back up, create a note, then restart the stack.
```

The named volume `mywebapp_postgres_data` remains after `docker compose down`.
Use `docker compose down -v` only when intentionally deleting database data.
