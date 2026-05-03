CHART_DIR := charts/pwpush-pro

.PHONY: lint template-starter template-advanced template-enterprise template package deps clean

lint:
	helm lint $(CHART_DIR)
	helm lint $(CHART_DIR) -f $(CHART_DIR)/values-advanced.yaml
	helm lint $(CHART_DIR) -f $(CHART_DIR)/values-enterprise.yaml

deps:
	helm dependency update $(CHART_DIR)

template-starter:
	helm template test-release $(CHART_DIR) \
		--set license.key=test-key

template-advanced:
	helm template test-release $(CHART_DIR) \
		-f $(CHART_DIR)/values-advanced.yaml \
		--set license.key=test-key

template-enterprise:
	helm template test-release $(CHART_DIR) \
		-f $(CHART_DIR)/values-enterprise.yaml \
		--set license.key=test-key

template: template-starter template-advanced template-enterprise

package: deps
	helm package $(CHART_DIR)

clean:
	rm -f *.tgz
	rm -rf $(CHART_DIR)/charts/*.tgz
